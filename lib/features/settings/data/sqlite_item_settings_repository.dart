import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/local_database_service.dart';
import '../domain/item_settings.dart';

class SqliteItemSettingsRepository implements ItemSettingsRepository {
  SqliteItemSettingsRepository(this._databaseService);

  static const _categoriesTable = 'item_categories';
  static const _unitsTable = 'item_units';
  static const _itemsTable = 'items';

  // Colunas comuns
  static const _colName = 'name';
  static const _colCreatedAt = 'created_at';

  final LocalDatabaseService _databaseService;

  @override
  Future<void> addCategory(String category) {
    return _addValue(
      value: category,
      tableName: _categoriesTable,
      valueLabel: 'categoria',
    );
  }

  @override
  Future<void> addUnit(String unit) {
    return _addValue(
      value: unit,
      tableName: _unitsTable,
      valueLabel: 'unidade',
    );
  }

  @override
  Future<ItemSettingsSnapshot> getSnapshot() async {
    final database = await _databaseService.database;

    final categories = await _getValuesFromTable(database, _categoriesTable);
    final units = await _getValuesFromTable(database, _unitsTable);

    return ItemSettingsSnapshot(categories: categories, units: units);
  }

  @override
  Future<void> removeCategory(String category) {
    return _removeValue(
      value: category,
      tableName: _categoriesTable,
      itemColumn: 'category',
      valueLabel: 'categoria',
    );
  }

  @override
  Future<void> removeUnit(String unit) {
    return _removeValue(
      value: unit,
      tableName: _unitsTable,
      itemColumn: 'unit',
      valueLabel: 'unidade',
    );
  }

  Future<void> _addValue({
    required String value,
    required String tableName,
    required String valueLabel,
  }) async {
    final normalizedValue = _normalizeValue(value, valueLabel: valueLabel);
    final database = await _databaseService.database;

    try {
      await database.insert(tableName, {
        _colName: normalizedValue,
        _colCreatedAt: DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw StateError('Esta $valueLabel ja esta cadastrada.');
      }
      rethrow;
    }
  }

  Future<void> _removeValue({
    required String value,
    required String tableName,
    required String itemColumn,
    required String valueLabel,
  }) async {
    final normalizedValue = _normalizeValue(value, valueLabel: valueLabel);
    final database = await _databaseService.database;
    final usageRows = await database.query(
      _itemsTable,
      columns: ['id'],
      where: '$itemColumn = ? COLLATE NOCASE',
      whereArgs: [normalizedValue],
      limit: 1,
    );

    if (usageRows.isNotEmpty) {
      throw StateError(
        'Nao e possivel remover esta $valueLabel porque ela esta em uso.',
      );
    }

    final deleted = await database.delete(
      tableName,
      where: '$_colName = ? COLLATE NOCASE',
      whereArgs: [normalizedValue],
    );

    if (deleted == 0) {
      throw StateError('A $valueLabel informada nao foi encontrada.');
    }
  }

  Future<List<String>> _getValuesFromTable(
    Database database,
    String tableName,
  ) async {
    final rows = await database.query(
      tableName,
      orderBy: 'name COLLATE NOCASE',
    );
    return rows
        .map((row) => (row['name'] as String? ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String _normalizeValue(String value, {required String valueLabel}) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      throw StateError('Informe uma $valueLabel valida.');
    }
    return normalizedValue;
  }
}
