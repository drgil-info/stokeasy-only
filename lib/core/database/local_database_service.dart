import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabaseService {
  LocalDatabaseService({
    this.databaseName = 'stokeasy.sqlite',
    this.inMemory = false,
  }) {
    if (!_sqfliteFactoryInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _sqfliteFactoryInitialized = true;
    }
  }

  final String databaseName;
  final bool inMemory;
  static bool _sqfliteFactoryInitialized = false;

  Database? _database;
  String? _databasePath;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _databasePath ??= await _resolveDatabasePath();
    _database = await databaseFactory.openDatabase(
      _databasePath!,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );

    return _database!;
  }

  Future<String> get databasePath async {
    _databasePath ??= await _resolveDatabasePath();
    return _databasePath!;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> restoreFrom(String sourcePath) async {
    if (inMemory) {
      throw StateError('Restauracao nao suportada em banco temporario.');
    }

    final targetPath = await databasePath;
    final normalizedSource = path.normalize(sourcePath);
    final normalizedTarget = path.normalize(targetPath);

    await close();

    if (normalizedSource != normalizedTarget) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw StateError('Arquivo de backup nao encontrado.');
      }

      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await sourceFile.copy(targetPath);
    }

    await database;
  }

  Future<String> _resolveDatabasePath() async {
    if (inMemory) {
      return inMemoryDatabasePath;
    }

    final baseDirectory = await databaseFactory.getDatabasesPath();
    await Directory(baseDirectory).create(recursive: true);

    return path.join(baseDirectory, databaseName);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        brand TEXT NOT NULL DEFAULT '',
        color TEXT NOT NULL DEFAULT '',
        quantity REAL NOT NULL DEFAULT 0,
        minimum_stock REAL NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        deactivated_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await _createItemSettingsTables(db);
    await _seedDefaultItemSettings(db);
    await _createMovementsTable(db);
    await _createMovementIndexes(db);
    await _createStockCountTables(db);
    await _createStockCountIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE items ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1;',
      );
      await db.execute('ALTER TABLE items ADD COLUMN deactivated_at TEXT;');

      await db.execute('PRAGMA foreign_keys = OFF;');
      await db.execute('ALTER TABLE movements RENAME TO movements_legacy;');
      await _createMovementsTable(db);
      await db.execute('''
        INSERT INTO movements (id, item_id, type, quantity, note, created_at)
        SELECT id, item_id, type, quantity, note, created_at
        FROM movements_legacy;
      ''');
      await db.execute('DROP TABLE movements_legacy;');
      await _createMovementIndexes(db);
      await db.execute('PRAGMA foreign_keys = ON;');
    }

    if (oldVersion < 3) {
      await _createStockCountTables(db);
      await _createStockCountIndexes(db);
    }

    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE items ADD COLUMN brand TEXT NOT NULL DEFAULT '';",
      );
      await db.execute(
        "ALTER TABLE items ADD COLUMN color TEXT NOT NULL DEFAULT '';",
      );
      await _createItemSettingsTables(db);
      await _seedDefaultItemSettings(db);
      await _syncItemSettingsWithItems(db);
    }
  }

  Future<void> _createItemSettingsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE,
        created_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> _seedDefaultItemSettings(DatabaseExecutor executor) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await executor.insert('item_categories', {
      'name': 'Geral',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await executor.insert('item_units', {
      'name': 'un',
      'created_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _syncItemSettingsWithItems(DatabaseExecutor executor) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final categoryRows = await executor.rawQuery('''
      SELECT DISTINCT TRIM(category) AS normalized_value
      FROM items
      WHERE TRIM(category) != ''
    ''');
    for (final row in categoryRows) {
      final value = (row['normalized_value'] as String? ?? '').trim();
      if (value.isEmpty) {
        continue;
      }

      await executor.insert('item_categories', {
        'name': value,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final unitRows = await executor.rawQuery('''
      SELECT DISTINCT TRIM(unit) AS normalized_value
      FROM items
      WHERE TRIM(unit) != ''
    ''');
    for (final row in unitRows) {
      final value = (row['normalized_value'] as String? ?? '').trim();
      if (value.isEmpty) {
        continue;
      }

      await executor.insert('item_units', {
        'name': value,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _createMovementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT
      );
    ''');
  }

  Future<void> _createMovementIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movements_item_id ON movements(item_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movements_created_at ON movements(created_at DESC);',
    );
  }

  Future<void> _createStockCountTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_counts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        opened_by TEXT NOT NULL,
        closed_by TEXT,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        notes TEXT NOT NULL DEFAULT '',
        closing_notes TEXT NOT NULL DEFAULT '',
        blind_mode INTEGER NOT NULL DEFAULT 0,
        total_items INTEGER NOT NULL DEFAULT 0,
        counted_items INTEGER NOT NULL DEFAULT 0,
        divergent_items INTEGER NOT NULL DEFAULT 0,
        selected_items INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_count_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        count_id INTEGER NOT NULL,
        item_id INTEGER,
        item_name TEXT NOT NULL,
        item_sku TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        unit TEXT NOT NULL DEFAULT '',
        system_quantity REAL NOT NULL DEFAULT 0,
        counted_quantity REAL,
        difference REAL,
        unit_cost REAL NOT NULL DEFAULT 0,
        selected_for_export INTEGER NOT NULL DEFAULT 1,
        line_note TEXT NOT NULL DEFAULT '',
        counted_by TEXT,
        counted_at TEXT,
        line_status TEXT NOT NULL DEFAULT 'pending',
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (count_id) REFERENCES stock_counts(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL
      );
    ''');
  }

  Future<void> _createStockCountIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_counts_opened_at ON stock_counts(opened_at DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_count_lines_count_id ON stock_count_lines(count_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_count_lines_status ON stock_count_lines(line_status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_count_lines_selected ON stock_count_lines(selected_for_export);',
    );
  }
}
