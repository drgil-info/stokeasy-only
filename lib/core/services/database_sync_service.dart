import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/local_database_service.dart';

/// Evento de sincronização que indica quais tabelas foram alteradas
class DatabaseSyncEvent {
  const DatabaseSyncEvent({
    required this.changedTables,
    required this.syncTime,
  });

  final Set<String> changedTables;
  final DateTime syncTime;

  bool hasChangesIn(String tableName) => changedTables.contains(tableName);
}

/// Serviço responsável por sincronizar e monitorar mudanças no banco de dados
/// Útil para aplicações multi-instância na mesma rede
class DatabaseSyncService {
  DatabaseSyncService({
    required LocalDatabaseService databaseService,
    this.syncIntervalSeconds = 10,
  }) : _databaseService = databaseService;

  final LocalDatabaseService _databaseService;
  final int syncIntervalSeconds;

  Timer? _syncTimer;
  final _syncController = StreamController<DatabaseSyncEvent>.broadcast();

  // Armazena hashes das tabelas para detectar mudanças
  final Map<String, String> _tableHashes = {};

  /// Stream que emite eventos quando detecta mudanças no banco de dados
  Stream<DatabaseSyncEvent> get syncStream => _syncController.stream;

  /// Inicia o monitoramento de mudanças do banco de dados
  Future<void> startSync() async {
    if (_syncTimer != null) {
      return; // Já está rodando
    }

    // Faz uma sincronização inicial
    await _checkForChanges();

    // Configura o timer para verificações periódicas
    _syncTimer = Timer.periodic(Duration(seconds: syncIntervalSeconds), (
      _,
    ) async {
      await _checkForChanges();
    });
  }

  /// Para o monitoramento de mudanças
  Future<void> stopSync() async {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Verifica se houve mudanças nas tabelas desde a última sincronização
  Future<void> _checkForChanges() async {
    try {
      final database = await _databaseService.database;
      final changedTables = <String>{};

      // Tabelas principais para monitorar
      const tablesToWatch = [
        'items',
        'movements',
        'item_settings',
        'stock_counts',
        'stock_count_lines',
      ];

      for (final tableName in tablesToWatch) {
        final currentHash = await _calculateTableHash(database, tableName);
        final previousHash = _tableHashes[tableName];

        if (previousHash != null && currentHash != previousHash) {
          changedTables.add(tableName);
        }

        _tableHashes[tableName] = currentHash;
      }

      if (changedTables.isNotEmpty) {
        _syncController.add(
          DatabaseSyncEvent(
            changedTables: changedTables,
            syncTime: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // Erro ao verificar mudanças (pode ser normal se banco está sendo acessado)
    }
  }

  /// Calcula um hash baseado nos dados e timestamps da tabela
  Future<String> _calculateTableHash(
    Database database,
    String tableName,
  ) async {
    try {
      final rows = await database.rawQuery(
        'SELECT COUNT(*) as count, MAX(updated_at) as last_update FROM $tableName',
      );

      if (rows.isEmpty) return '';

      final row = rows.first;
      final count = row['count'] as int?;
      final lastUpdate = row['last_update'] as String?;

      return '$count:$lastUpdate'.hashCode.toString();
    } catch (e) {
      // Tabela pode não existir ou ter estrutura diferente
      return '';
    }
  }

  /// Força uma sincronização imediata
  /// Útil quando o app sabe que algo mudou (ex: após uma operação)
  Future<void> syncNow() async {
    await _checkForChanges();
  }

  /// Limpa os recursos
  Future<void> dispose() async {
    await stopSync();
    await _syncController.close();
  }
}
