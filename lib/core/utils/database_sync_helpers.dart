import 'dart:async';

import 'package:flutter/material.dart';

import '../services/database_sync_service.dart';

/// Mixin que fornece auto-sincronização para StatefulWidgets
///
/// Uso:
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   State<MyPage> createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage> with DatabaseAutoSyncMixin {
///   @override
///   void initState() {
///     super.initState();
///     setupDatabaseSync(
///       databaseSyncService: syncService,
///       tablesToWatch: {'items', 'movements'},
///       onDataChanged: _refreshData,
///     );
///   }
///
///   void _refreshData() {
///     setState(() {
///       // Recarregar dados
///     });
///   }
///
///   @override
///   void dispose() {
///     disposeDatabaseSync();
///     super.dispose();
///   }
/// }
/// ```
mixin DatabaseAutoSyncMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<DatabaseSyncEvent>? _syncSubscription;

  /// Configura a sincronização automática de banco de dados
  void setupDatabaseSync({
    required DatabaseSyncService databaseSyncService,
    required Set<String> tablesToWatch,
    required VoidCallback onDataChanged,
    bool shouldDebounce = true,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) {
    Timer? debounceTimer;

    _syncSubscription = databaseSyncService.syncStream.listen((event) {
      // Verifica se alguma tabela assistida foi modificada
      final hasRelevantChanges = tablesToWatch.any(event.hasChangesIn);

      if (!hasRelevantChanges) return;

      if (shouldDebounce) {
        // Debounce para evitar múltiplas atualizações em sequência
        debounceTimer?.cancel();
        debounceTimer = Timer(debounceDuration, () {
          if (mounted) {
            onDataChanged();
          }
        });
      } else {
        if (mounted) {
          onDataChanged();
        }
      }
    });
  }

  /// Libera os recursos da sincronização
  void disposeDatabaseSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
  }
}

/// Hook para usar em Widgets stateless com Riverpod ou Provider
///
/// Exemplo de uso com FutureBuilder:
/// ```dart
/// final itemsProvider = FutureProvider((ref) async {
///   final syncService = ref.watch(databaseSyncServiceProvider);
///   final repository = ref.watch(itemsRepositoryProvider);
///
///   // Escuta sincronização
///   ref.watch(
///     databaseSyncProvider(syncService).map(
///       (event) => event.hasChangesIn('items'),
///     ),
///   );
///
///   return repository.getItems();
/// });
/// ```
class DatabaseSyncHelper {
  /// Cria um future que se resolve quando há mudanças em tabelas específicas
  static Future<void> listenForChanges({
    required DatabaseSyncService syncService,
    required Set<String> tablesToWatch,
    required Duration timeout,
  }) async {
    final completer = Completer<void>();

    final subscription = syncService.syncStream.listen((event) {
      final hasRelevantChanges = tablesToWatch.any(event.hasChangesIn);
      if (hasRelevantChanges && !completer.isCompleted) {
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(timeout);
    } finally {
      subscription.cancel();
    }
  }

  /// Periodicamente recarrega dados até que não haja mais mudanças
  static Future<T> withAutoSync<T>({
    required DatabaseSyncService syncService,
    required Set<String> tablesToWatch,
    required Future<T> Function() fetcher,
    Duration syncCheckInterval = const Duration(seconds: 2),
    Duration maxWaitTime = const Duration(seconds: 30),
  }) async {
    bool hadChanges = false;

    final subscription = syncService.syncStream.listen((event) {
      final hasRelevantChanges = tablesToWatch.any(event.hasChangesIn);
      if (hasRelevantChanges) {
        hadChanges = true;
      }
    });

    try {
      T result = await fetcher();

      // Aguarda um tempo para verificar se houve mais mudanças
      final waitDeadline = DateTime.now().add(maxWaitTime);

      while (hadChanges && DateTime.now().isBefore(waitDeadline)) {
        hadChanges = false;
        await Future.delayed(syncCheckInterval);

        if (hadChanges) {
          result = await fetcher();
        }
      }

      return result;
    } finally {
      subscription.cancel();
    }
  }
}
