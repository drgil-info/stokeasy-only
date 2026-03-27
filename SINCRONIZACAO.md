# Sistema de Sincronização de Banco de Dados em Rede

## Visão Geral

O StokEasy agora possui um sistema automático de sincronização de banco de dados que permite múltiplas instâncias do aplicativo em diferentes máquinas da rede compartilharem dados em tempo real.

## Como Funciona

1. **Database Sync Service**: Um serviço que roda em background verificando mudanças no banco de dados SQLite
2. **Polling Periódico**: A cada X segundos (padrão: 10s), o serviço calcula um hash das tabelas para detectar alterações
3. **Auto-refresh**: Quando mudanças são detectadas, o app automaticamente recarrega os dados afetados
4. **Debounce**: Múltiplas mudanças em rápida sequência são agrupadas para evitar atualizações excessivas

## Configuração

### Intervalo de Sincronização

O intervalo padrão é **10 segundos**. Para alterar, edite `lib/app/bootstrap.dart`:

```dart
final databaseSyncService = DatabaseSyncService(
  databaseService: databaseService,
  syncIntervalSeconds: 10,  // ← Mude este valor (em segundos)
);
```

**Recomendações:**
- **5 segundos**: Sincronização muito frequente, consome mais recursos
- **10 segundos**: Balance entre responsividade e performance (padrão)
- **30+ segundos**: Sincronização menos frequente, menos recursos

### Tabelas Monitoradas

Por padrão, estas tabelas são monitoradas:
- `items` - Produtos cadastrados
- `movements` - Entradas e saídas de estoque
- `item_settings` - Categorias e unidades
- `stock_counts` - Contagens de estoque
- `stock_count_lines` - Detalhes das contagens

Para adicionar mais tabelas, edite `lib/core/services/database_sync_service.dart`:

```dart
const tablesToWatch = [
  'items',
  'movements',
  'item_settings',
  'stock_counts',
  'stock_count_lines',
  // Adicione mais tabelas aqui
];
```

## Uso em Componentes

### Opção 1: Usando o Mixin DatabaseAutoSyncMixin (StatefulWidgets)

Para widgets estateful que precisam atualizar quando os dados mudam:

```dart
import 'package:stokeasy/core/utils/database_sync_helpers.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with DatabaseAutoSyncMixin {
  late List<InventoryItem> _items;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Configura auto-sync
    setupDatabaseSync(
      databaseSyncService: syncService,
      tablesToWatch: {'items'},
      onDataChanged: _refreshData,
    );
  }
  
  void _refreshData() {
    print('Dados mudaram, atualizando...');
    setState(() {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    _items = await repository.getItems();
  }
  
  @override
  void dispose() {
    disposeDatabaseSync();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Seu widget aqui
    return ListView(
      children: _items.map((item) => Text(item.name)).toList(),
    );
  }
}
```

### Opção 2: Usando DatabaseSyncHelper (FutureBuilder)

Para mais controle sobre quando e como os dados são carregados:

```dart
Future<List<InventoryItem>> _fetchItemsWithSync() async {
  return DatabaseSyncHelper.withAutoSync(
    syncService: widget.dependencies.databaseSyncService,
    tablesToWatch: {'items'},
    fetcher: () => widget.dependencies.getItemsUseCase.call(),
    syncCheckInterval: Duration(seconds: 2),
    maxWaitTime: Duration(seconds: 30),
  );
}

@override
Widget build(BuildContext context) {
  return FutureBuilder<List<InventoryItem>>(
    future: _fetchItemsWithSync(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Erro: ${snapshot.error}'));
      }
      final items = snapshot.data ?? [];
      return ListView(
        children: items.map((item) => Text(item.name)).toList(),
      );
    },
  );
}
```

### Opção 3: Escutando Diretamente o Stream (Avançado)

Para ter controle total sobre os eventos de sincronização:

```dart
StreamBuilder<DatabaseSyncEvent>(
  stream: widget.dependencies.databaseSyncService.syncStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final event = snapshot.data!;
      if (event.hasChangesIn('items')) {
        print('Itens foram alterados em: ${event.syncTime}');
        // Recarregar dados aqui
      }
    }
    return YourWidget();
  },
)
```

## Troubleshooting

### Dados não sincronizam

1. **Verificar se o serviço foi iniciado**:
   - O `DatabaseSyncService.startSync()` é chamado no `AppShell.initState()`
   - Verifique o console para mensagens de erro

2. **Verificar se as tabelas estão no monitor**:
   - Edite `_tablesToWatch` em `database_sync_service.dart`
   - Garanta que a tabela exista

3. **Aumentar o intervalo de sincronização**:
   - Aumente `syncIntervalSeconds` se houver muitas mudanças

### Performance ruim

1. **Aumentar o intervalo**:
   ```dart
   syncIntervalSeconds: 30,  // Aumentar de 10 para 30
   ```

2. **Remover tabelas desnecessárias**:
   - Edite `const tablesToWatch` para monitorar apenas as tabelas essenciais

3. **Usar debounce maior**:
   - No mixin, aumente `debounceDuration`

### Banco de dados "travado"

Se o banco ficar travado durante sincronização:

1. Verifique se outras instâncias estão acessando simultaneamente
2. O SQLite tem limitações de escrita em rede
3. Considere usar um banco de dados servidor (PostgreSQL) para > 5 usuários simultâneos

## Performance e Escalabilidade

### Estimativas

- **1-3 usuários**: Sem problemas com intervalo de 10s
- **4-5 usuários**: Considere aumentar para 20s ou usar debounce de 500ms
- **6+ usuários**: Recomenda-se migrar para banco de dados servidor

### Otimizações

1. **Aumentar intervalo para casos pouco sensíveis**:
   ```dart
   // Para settings (mudanças raras)
   if (event.hasChangesIn('item_settings')) {
     // Recarregar apenas se houver mudanças
   }
   ```

2. **Usar polling seletivo**:
   - Monitorar apenas tabelas que mudam frequentemente

3. **Implementar websockets** (futuro):
   - Para verdadeira sincronização em tempo real (0.5s)

## Limitações e Considerações

⚠️ **SQLite em Rede:**
- SQLite tem limitações para compartilhamento em rede
- Máximo de ~5-10 usuários simultâneos recomendado
- Sem suporte a transações distribuídas

✅ **O que este sistema oferece:**
- Auto-refresh automático quando dados mudam
- Sem necessidade de sair/reentrar no app
- Sincronização periódica confiável

### Alternativas para Escala Maior

Se o projeto crescer para muitos usuários:

1. **Migrar para PostgreSQL + API REST**
2. **Implementar WebSockets para sync em tempo real**
3. **Usar Firebase Realtime Database**
4. **Implementar sincronização por arquivo delta**

## Desabilitando Sincronização

Para desabilitar o sistema de sincronização:

```dart
// Em app_shell.dart, no initState():
// Comente ou remova esta linha:
// _setupDatabaseSync();
```

Ou modifique o serviço:

```dart
// Em bootstrap.dart, não chame:
// await widget.dependencies.databaseSyncService.startSync();
```

## Monitoramento

Para debug, adicione logs na classe `DatabaseSyncService`:

```dart
Future<void> _checkForChanges() async {
  print('[DatabaseSync] Verificando mudanças...');
  // ... resto do código
  if (changedTables.isNotEmpty) {
    print('[DatabaseSync] Mudanças detectadas em: $changedTables');
  }
}
```

## Contato e Suporte

Para dúvidas sobre a implementação de sincronização, verifique:
- `lib/core/services/database_sync_service.dart` - Lógica principal
- `lib/core/utils/database_sync_helpers.dart` - Utilitários
- `lib/shared/navigation/app_shell.dart` - Integração no app
