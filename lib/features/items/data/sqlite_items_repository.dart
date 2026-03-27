import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/local_database_service.dart';
import '../domain/items.dart';

class SqliteItemsRepository implements ItemsRepository {
  SqliteItemsRepository(this._databaseService);

  static const _generatedSkuPrefix = 'ITEM-';

  final LocalDatabaseService _databaseService;

  Future<String> _resolveSku(
    Database database,
    String rawSku, {
    String? fallbackSku,
  }) async {
    final normalizedSku = rawSku.trim();
    if (normalizedSku.isNotEmpty) {
      return normalizedSku;
    }
    if (fallbackSku != null && fallbackSku.trim().isNotEmpty) {
      return fallbackSku.trim();
    }

    final rows = await database.query('items', columns: ['sku']);
    var highestSequence = 0;

    for (final row in rows) {
      final sku = (row['sku'] as String? ?? '').trim();
      if (!sku.startsWith(_generatedSkuPrefix)) {
        continue;
      }

      final sequence = int.tryParse(sku.substring(_generatedSkuPrefix.length));
      if (sequence != null && sequence > highestSequence) {
        highestSequence = sequence;
      }
    }

    final nextSequence = (highestSequence + 1).toString().padLeft(4, '0');
    return '$_generatedSkuPrefix$nextSequence';
  }

  @override
  Future<InventoryItem> createItem(InventoryItemDraft draft) async {
    draft.validate();

    final database = await _databaseService.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final sku = await _resolveSku(database, draft.sku);
    final normalizedCategory = draft.category.trim();
    final normalizedUnit = draft.unit.trim();
    final normalizedBrand = draft.brand.trim();
    final normalizedColor = draft.color.trim();

    try {
      await _upsertItemSettings(
        database,
        category: normalizedCategory,
        unit: normalizedUnit,
      );

      final id = await database.insert('items', {
        'name': draft.name.trim(),
        'sku': sku,
        'category': normalizedCategory,
        'unit': normalizedUnit,
        'brand': normalizedBrand,
        'color': normalizedColor,
        'quantity': draft.initialQuantity,
        'minimum_stock': draft.minimumStock,
        'price': draft.price,
        'is_active': 1,
        'deactivated_at': null,
        'created_at': now,
        'updated_at': now,
      });

      final createdRows = await database.query(
        'items',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return _mapItem(createdRows.first);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw StateError('Ja existe um item cadastrado com esse codigo.');
      }
      rethrow;
    }
  }

  @override
  Future<void> deactivateItem(int id) async {
    final database = await _databaseService.database;
    final rows = await database.query(
      'items',
      columns: ['id', 'quantity', 'is_active'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('O item selecionado nao foi encontrado.');
    }

    final item = rows.first;
    if ((item['is_active'] as num?)?.toInt() == 0) {
      return;
    }

    if (_toDouble(item['quantity']) != 0) {
      throw StateError(
        'Somente itens com estoque zerado podem ser inativados.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await database.update(
      'items',
      {'is_active': 0, 'deactivated_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<InventoryItem>> getItems({
    String query = '',
    ItemStatusFilter status = ItemStatusFilter.all,
    String category = '',
    String unit = '',
    ItemSortOption sort = ItemSortOption.newest,
  }) async {
    final database = await _databaseService.database;
    final normalizedQuery = query.trim();
    final normalizedCategory = category.trim();
    final normalizedUnit = unit.trim();
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    switch (status) {
      case ItemStatusFilter.active:
        whereClauses.add('is_active = 1');
      case ItemStatusFilter.inactive:
        whereClauses.add('is_active = 0');
      case ItemStatusFilter.all:
        break;
    }
    if (normalizedQuery.isNotEmpty) {
      whereClauses.add(
        '(name LIKE ? OR sku LIKE ? OR category LIKE ? OR brand LIKE ? OR color LIKE ?)',
      );
      whereArgs.addAll(List.filled(5, '%$normalizedQuery%'));
    }
    if (normalizedCategory.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(normalizedCategory);
    }
    if (normalizedUnit.isNotEmpty) {
      whereClauses.add('unit = ?');
      whereArgs.add(normalizedUnit);
    }

    final orderBy = switch (sort) {
      ItemSortOption.nameAsc => 'is_active DESC, name COLLATE NOCASE ASC',
      ItemSortOption.newest => 'is_active DESC, updated_at DESC, name ASC',
      ItemSortOption.highestStock =>
        'is_active DESC, quantity DESC, name COLLATE NOCASE ASC',
      ItemSortOption.lowestStock =>
        'is_active DESC, quantity ASC, name COLLATE NOCASE ASC',
      ItemSortOption.highestValue =>
        'is_active DESC, (quantity * price) DESC, name COLLATE NOCASE ASC',
    };

    final rows = await database.query(
      'items',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return rows.map(_mapItem).toList();
  }

  @override
  Future<void> reactivateItem(int id) async {
    final database = await _databaseService.database;
    final rows = await database.query(
      'items',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('O item selecionado nao foi encontrado.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await database.update(
      'items',
      {'is_active': 1, 'deactivated_at': null, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateItem(int id, InventoryItemDraft draft) async {
    draft.validate();

    final database = await _databaseService.database;
    final currentRows = await database.query(
      'items',
      columns: ['quantity', 'created_at', 'sku', 'is_active', 'deactivated_at'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (currentRows.isEmpty) {
      throw StateError('O item selecionado nao foi encontrado.');
    }

    final currentItem = currentRows.first;
    final sku = await _resolveSku(
      database,
      draft.sku,
      fallbackSku: currentItem['sku'] as String?,
    );
    final normalizedCategory = draft.category.trim();
    final normalizedUnit = draft.unit.trim();
    final normalizedBrand = draft.brand.trim();
    final normalizedColor = draft.color.trim();

    try {
      await _upsertItemSettings(
        database,
        category: normalizedCategory,
        unit: normalizedUnit,
      );

      await database.update(
        'items',
        {
          'name': draft.name.trim(),
          'sku': sku,
          'category': normalizedCategory,
          'unit': normalizedUnit,
          'brand': normalizedBrand,
          'color': normalizedColor,
          'quantity': _toDouble(currentItem['quantity']),
          'minimum_stock': draft.minimumStock,
          'price': draft.price,
          'is_active': (currentItem['is_active'] as num?)?.toInt() ?? 1,
          'deactivated_at': currentItem['deactivated_at'],
          'created_at': currentItem['created_at'],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw StateError('Ja existe um item cadastrado com esse codigo.');
      }
      rethrow;
    }
  }

  InventoryItem _mapItem(Map<String, Object?> row) {
    return InventoryItem(
      id: row['id'] as int,
      name: row['name'] as String? ?? '',
      sku: row['sku'] as String? ?? '',
      category: row['category'] as String? ?? '',
      unit: row['unit'] as String? ?? '',
      brand: row['brand'] as String? ?? '',
      color: row['color'] as String? ?? '',
      quantity: _toDouble(row['quantity']),
      minimumStock: _toDouble(row['minimum_stock']),
      price: _toDouble(row['price']),
      isActive: (row['is_active'] as num?)?.toInt() != 0,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }

  Future<void> _upsertItemSettings(
    DatabaseExecutor executor, {
    required String category,
    required String unit,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await executor.insert('item_categories', {
      'name': category,
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await executor.insert('item_units', {
      'name': unit,
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  double _toDouble(Object? value) {
    return (value as num?)?.toDouble() ?? 0;
  }
}
