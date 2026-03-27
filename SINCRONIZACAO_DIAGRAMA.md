# Fluxo de Sincronização - Diagrama Visual

## 🔄 Ciclo de Sincronização Automática

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPUTADOR 1 (Usuário A)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  StokEasy App em Execução                                     │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │  DatabaseSyncService                                   │  │  │
│  │  │  ⏰ Timer: A cada 10 segundos                          │  │  │
│  │  │  - Verifica mudanças no SQLite                         │  │  │
│  │  │  - Calcula hash das tabelas                            │  │  │
│  │  │  - Emite evento se detectar mudança                    │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  │                          ↓                                    │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │  AppShell - Listener                                   │  │  │
│  │  │  Escuta eventos do DatabaseSyncService                 │  │  │
│  │  │  ┌──────────────────────────────────────────────────┐  │  │  │
│  │  │  │Quando mudança em 'items' é detectada:           │  │  │  │
│  │  │  │ 1. Chama _refreshInventoryData()                 │  │  │  │
│  │  │  │ 2. Recarrega dados dos repositórios              │  │  │  │
│  │  │  │ 3. UI atualiza automaticamente!                  │  │  │  │
│  │  │  └──────────────────────────────────────────────────┘  │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
                    📁 SQLite Compartilhado
                    (arquivo .sqlite na rede)
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPUTADOR 2 (Usuário B)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  StokEasy App em Execução                                     │  │
│  │                                                               │  │
│  │  👤 Usuário B faz uma ação:                                 │  │
│  │     ➕ Adiciona um novo produto                             │  │
│  │                                                               │  │
│  │  SQLite é atualizado com o novo produto                      │  │
│  │                                                               │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │  DatabaseSyncService                                   │  │  │
│  │  │  ⏰ Na próxima verificação (até 10 segundos):           │  │  │
│  │  │  ✓ Detecta: hash de 'items' mudou!                     │  │  │
│  │  │  ✓ Emite evento: DatabaseSyncEvent                     │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  │                          ↓                                    │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │  AppShell - Listener (Computador 1)                    │  │  │
│  │  │  Recebe evento de mudança em 'items'                   │  │  │
│  │  │  ┌──────────────────────────────────────────────────┐  │  │  │
│  │  │  │ setState(() {                                     │  │  │  │
│  │  │  │   _refreshInventoryData() // Recarrega!          │  │  │  │
│  │  │  │ })                                                │  │  │  │
│  │  │  │                                                   │  │  │  │
│  │  │  │ ✨ UI do Computador 1 atualiza                   │  │  │  │
│  │  │  │ ✨ Novo produto aparece automaticamente!         │  │  │  │
│  │  │  └──────────────────────────────────────────────────┘  │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  👤 Usuário A vê o novo produto SEM PRECISAR                        │
│     SAIR E REENTRAR DO PROGRAMA! ✨                               │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## 📈 Linha do Tempo de Sincronização

```
Computador A                           Computador B
─────────────                          ─────────────

T=0s
│ DatabaseSync verifica (Hash: ABC)
│
T=5s
│ DatabaseSync verifica (Hash: ABC)
│
T=10s
│ DatabaseSync verifica (Hash: ABC)
│
T=15s
│ DatabaseSync verifica (Hash: ABC)
│                                      T=12s
│                                      Usuário B adiciona produto
│                                      Hash muda de ABC para XYZ
│
T=20s
│ DatabaseSync verifica
│ ⚠️ Hash mudou! (ABC → XYZ)
│ 📢 Emite evento
│ 🔄 Recarrega dados
│ ✨ UI atualiza
│ Usuário A vê o novo produto!
```

## 🎯 O que Muda

### Computador 1 (observação)

```
ANTES (sem sincronização):
┌─────────────────────────────────┐
│ Produto A                       │
│ Produto B                       │
│                                 │
│ ❌ Novo produto adicionado por │
│    Usuário B em outro PC?      │
│ ❌ NÃO aparece aqui!           │
│                                 │
│ ❌ Usuário A precisa sair da   │
│    app e reentrar para ver    │
└─────────────────────────────────┘

DEPOIS (com sincronização):
┌─────────────────────────────────┐
│ Produto A                       │
│ Produto B                       │
│ Produto C (novo!)  ✨           │
│                                 │
│ ✅ Aparece automaticamente      │
│    após ~10 segundos            │
│                                 │
│ ✅ Nenhuma ação necesária       │
│    do usuário!                 │
└─────────────────────────────────┘
```

## 🔗 Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    Aplicativo Flutter                     │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │           App Shell (Ponto de Entrada)            │  │
│  │  - Inicializa DatabaseSyncService                │  │
│  │  - Configura listener para eventos               │  │
│  │  - Chama _refreshInventoryData() ao detectar     │  │
│  │    mudanças                                      │  │
│  └──────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │      DatabaseSyncService (Novo! ⭐)             │  │
│  │  - Timer que roda cada 10 segundos               │  │
│  │  - Calcula hash das tabelas                      │  │
│  │  - Emite eventos quando detecta mudanças         │  │
│  │  - Monitora: items, movements, stock_counts...   │  │
│  └──────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │          Controllers/Pages                        │  │
│  │  - ItemsController                               │  │
│  │  - MovementsController                           │  │
│  │  - DashboardController                           │  │
│  │  - etc (eles recarregam ao receber notificação) │  │
│  └──────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │       LocalDatabaseService (SQLite)              │  │
│  │  - Acesso ao banco de dados local                │  │
│  │  - Queries e atualização de dados                │  │
│  └──────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │   SQLite Arquivo (.sqlite) COMPARTILHADO        │  │
│  │   Em rede: \\servidor\compartilhamento\db.sqlite │  │
│  │   Ou local: C:\Programas\stokeasy\banco.sqlite   │  │
│  └──────────────────────────────────────────────────┘  │
│                          ↑                              │
│         (Múltiplos PCs acessam este arquivo)          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Estados Possíveis

```
┌─────────────────────────┐
│  Sincronização Inativa  │
│  (App acaba de abrir)   │
└──────────────┬──────────┘
               ↓
        startSync() chamado
               ↓
┌─────────────────────────────────────────┐
│  Sincronização Ativa - Aguardando       │
│  - Timer rodando                        │
│  - Nenhuma mudança detectada            │
│  - Aplicação funciona normalmente       │
└──────────────┬──────────────────────────┘
               ↓
         Mudança detectada
           (10 segundos)
               ↓
┌─────────────────────────────────────────┐
│  Sincronização Ativa - Atualizando      │
│  - Evento emitido                       │
│  - Dados recarregados                   │
│  - UI atualiza                          │
└──────────────┬──────────────────────────┘
               ↓
  Volta para "Aguardando"
```

## 💡 Situações Comuns

### Cenário 1: Sincronização Bem-Sucedida
```
10:30:45 → Usuário A está vendo a lista de produtos
10:30:50 → Usuário B (outro PC) adiciona "Produto XYZ"
10:30:50 → SQLite atualizado
10:30:56 → DatabaseSyncService detecta mudança
10:30:56 → AppShell recarrega dados
10:30:56 → ✨ Usuário A vê "Produto XYZ" aparecendo!
```

### Cenário 2: Múltiplas Mudanças
```
10:40:00 → Usuário B adiciona Produto 1
10:40:02 → Usuário C adiciona Produto 2  
10:40:04 → Usuário B edita Movimento
(DatabaseSync verifica a cada 10s, agrega mudanças)
10:40:06 → DatabaseSync detecta TODAS as 3 mudanças
10:40:06 → Uma única atualização na UI
           (débounce evita múltiplas atualizações)
```

---

**Ilustração criada:** 27/03/2026
