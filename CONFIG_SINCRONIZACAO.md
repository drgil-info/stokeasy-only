# Guia de Configuração de Sincronização

## Cenários Recomendados

### 1. Pequeno Escritório (1-3 Usuários)

**Configuração em `lib/app/bootstrap.dart`:**
```dart
final databaseSyncService = DatabaseSyncService(
  databaseService: databaseService,
  syncIntervalSeconds: 10, // Padrão - bom balance
);
```

**Benefícios:**
- Sincronização confiável
- Sem problemas de performance
- Atualização rápida (até 10 segundos)

### 2. Escritório Médio (4-8 Usuários)

**Configuração:**
```dart
final databaseSyncService = DatabaseSyncService(
  databaseService: databaseService,
  syncIntervalSeconds: 15, // Aumentado para menos overhead
);
```

**Ajustar debounce em `app_shell.dart`:**
```dart
setupDatabaseSync(
  databaseSyncService: widget.dependencies.databaseSyncService,
  tablesToWatch: {'items', 'movements', 'movements'},
  onDataChanged: () {
    if (mounted) {
      unawaited(_refreshInventoryData());
    }
  },
  shouldDebounce: true,
  debounceDuration: const Duration(milliseconds: 800), // Aumentado
);
```

### 3. Muitos Usuários (9+)

**⚠️ Não recomendado com SQLite em Rede**

Se necessário:
```dart
final databaseSyncService = DatabaseSyncService(
  databaseService: databaseService,
  syncIntervalSeconds: 30, // Muito maior
);
```

**Alternativa Recomendada:** Migrar para PostgreSQL com API REST

## Ajustes por Tipo de Uso

### Alta Frequência de Mudanças
```dart
syncIntervalSeconds: 5,  // Verificações mais frequentes
debounceDuration: const Duration(milliseconds: 200), // Débounce menor
```

### Alterações Raras
```dart
syncIntervalSeconds: 30,  // Verificações menos frequentes
debounceDuration: const Duration(milliseconds: 1000), // Débounce maior
```

### Rede Instável
```dart
syncIntervalSeconds: 20,  // Menor frequência
debounceDuration: const Duration(milliseconds: 500),
```

## Monitoramento

### Ver se sincronização está ativa

Adicione este código temporariamente em `database_sync_service.dart`:

```dart
Future<void> _checkForChanges() async {
  try {
    // ... código existente ...
    if (changedTables.isNotEmpty) {
      debugPrint('[SYNC] Tabelas atualizadas: $changedTables');
      _syncController.add(
        DatabaseSyncEvent(
          changedTables: changedTables,
          syncTime: DateTime.now(),
        ),
      );
    }
  } catch (e) {
    debugPrint('[SYNC] Erro: $e');
  }
}
```

### Performance Metrics

Para medir performance, adicione em `app_shell.dart`:

```dart
DateTime? _lastSync;
int _syncCount = 0;

void _setupDatabaseSync() {
  unawaited(widget.dependencies.databaseSyncService.startSync());

  _databaseSyncSubscription =
      widget.dependencies.databaseSyncService.syncStream.listen((event) {
    _syncCount++;
    final now = DateTime.now();
    if (_lastSync != null) {
      final elapsed = now.difference(_lastSync!).inMilliseconds;
      debugPrint('[PERF] Sync #$_syncCount em ${elapsed}ms');
    }
    _lastSync = now;

    if (event.hasChangesIn('items') || /* ... */) {
      if (mounted) {
        unawaited(_refreshInventoryData());
      }
    }
  });
}
```

## Troubleshooting Performance

### CPU Alto
- ✅ Aumentar `syncIntervalSeconds` para 30
- ✅ Aumentar `debounceDuration` para 1000ms
- ❌ Diminuir intervalo

### Uso de Memória Alto
- ✅ Limpar dados não utilizados
- ✅ Usar streams ao invés de listas em memória
- ❌ Aumentar frequência de sync

### Banco Travado
- ✅ Aumentar intervalo para 30+ segundos
- ✅ Reduzir número de usuários simultâneos
- ✅ Considerar migração para PostgreSQL

## Migração para PostgreSQL

Quando o projeto crescer:

1. **Instalar pacote PostgreSQL:**
```bash
flutter pub add postgres
```

2. **Criar nova camada de sincronização:**
```dart
class PostgresSync {
  // Implementar sincronização via API
}
```

3. **Benefícios:**
- Suporte real-time com WebSockets
- Múltiplos usuários simultâneos
- Transações distribuídas
- Escalabilidade horizontal

## Suporte

Se tiver dúvidas sobre configuração:

1. Verifique `SINCRONIZACAO.md`
2. Veja exemplos em `lib/core/examples/sync_example.dart`
3. Consulte logs em `database_sync_service.dart`
