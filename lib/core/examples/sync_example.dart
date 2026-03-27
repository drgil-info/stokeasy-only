import 'package:flutter/material.dart';

import '../../app/bootstrap.dart';
import '../../core/utils/database_sync_helpers.dart';

/// Exemplo de uso do sistema de sincronização de banco de dados
///
/// Este exemplo mostra como implementar auto-sincronização em um componente
/// que exibe uma lista de itens. Quando outro computador na rede muda algo,
/// esta tela atualiza automaticamente sem precisar sair/reentrar.

class SyncExamplePage extends StatefulWidget {
  const SyncExamplePage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SyncExamplePage> createState() => _SyncExamplePageState();
}

class _SyncExamplePageState extends State<SyncExamplePage>
    with DatabaseAutoSyncMixin {
  late List<dynamic> _items;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _items = [];

    // Carrega dados inicialmente
    _loadItems();

    // Configura sincronização automática
    // Quando a tabela 'items' mudar, chama _loadItems() automaticamente
    setupDatabaseSync(
      databaseSyncService: widget.dependencies.databaseSyncService,
      tablesToWatch: {'items'}, // Monitorar apenas a tabela 'items'
      onDataChanged: _loadItems,
      shouldDebounce: true,
      debounceDuration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _loadItems() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Aqui você carregaria os dados do repositório
      // final items = await widget.dependencies.getItemsUseCase.call();

      if (mounted) {
        setState(() {
          // _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Importante: sempre limpar a sincronização
    disposeDatabaseSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemplo de Sincronização')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Erro ao carregar dados'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadItems,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('Nenhum item encontrado'));
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          title: Text(item.toString()),
          subtitle: const Text('Sincronizado automaticamente'),
        );
      },
    );
  }
}

/// Exemplo 2: Usando FutureBuilder com sincronização
///
/// Alternativa mais simples sem precisa usar um mixin
class SyncExamplePage2 extends StatefulWidget {
  const SyncExamplePage2({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SyncExamplePage2> createState() => _SyncExamplePageState2();
}

class _SyncExamplePageState2 extends State<SyncExamplePage2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemplo FutureBuilder')),
      body: FutureBuilder(
        future: _fetchDataWithSync(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) => ListTile(
              title: Text('Item $index'),
              subtitle: const Text('Sincronizado automaticamente'),
            ),
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _fetchDataWithSync() async {
    return DatabaseSyncHelper.withAutoSync(
      syncService: widget.dependencies.databaseSyncService,
      tablesToWatch: {'items'},
      fetcher: () async {
        // Simula carregamento de dados
        await Future.delayed(const Duration(milliseconds: 500));
        return [1, 2, 3, 4, 5];
      },
      syncCheckInterval: const Duration(seconds: 2),
      maxWaitTime: const Duration(seconds: 30),
    );
  }
}

/// Exemplo 3: Sincronizando múltiplas tabelas
class SyncExamplePage3 extends StatefulWidget {
  const SyncExamplePage3({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SyncExamplePage3> createState() => _SyncExamplePageState3();
}

class _SyncExamplePageState3 extends State<SyncExamplePage3>
    with DatabaseAutoSyncMixin {
  @override
  void initState() {
    super.initState();

    // Monitorar múltiplas tabelas
    setupDatabaseSync(
      databaseSyncService: widget.dependencies.databaseSyncService,
      tablesToWatch: {
        'items', // Produtos
        'movements', // Entradas/saídas
        'item_settings', // Categorias e unidades
      },
      onDataChanged: () {
        // Recarregar tudo quando qualquer tabela mudar
        if (mounted) {
          setState(() {
            // Reload data here
          });
        }
      },
    );
  }

  @override
  void dispose() {
    disposeDatabaseSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronização Múltiplas Tabelas')),
      body: const Center(
        child: Text('Monitorando: items, movements, item_settings'),
      ),
    );
  }
}
