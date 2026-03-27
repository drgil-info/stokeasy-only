# FAQ - Perguntas Frequentes sobre Sincronização

## ❓ Perguntas Comuns

### 1. "Preciso fazer algo especial para usar?"
**Resposta:** ❌ Não! A sincronização já está ativa por padrão. Apenas use o programa normalmente.

Quando alguém muda algo em outro computador, seu programa atualiza automaticamente em até 10 segundos.

---

### 2. "Por quanto tempo leva para sincronizar?"
**Resposta:** Até **10 segundos** (configurável).

- Segundo 0-10: Mudança é feita em outro PC
- Segundo 10: Seu PC detecta a mudança
- Segundo 10-11: Seus dados recarregam
- Segundo 11: ✨ Você vê a mudança!

Para sincronização **mais rápida** (5 segundos): Veja `CONFIG_SINCRONIZACAO.md`

---

### 3. "E se muitos usuários mexerem ao mesmo tempo?"
**Resposta:** Funciona bem para **1-5 usuários simultâneos**.

Se tiver 6+ usuários, entre em contato para discutir alternativas (PostgreSQL).

---

### 4. "O sistema usa muita internet?"
**Resposta:** ❌ Não usa internet!

Funciona **apenas em rede local (LAN)** porque SQLite acessa um arquivo compartilhado:
- ✅ Escritório na mesma sala
- ✅ Diferentes salas do mesmo prédio
- ❌ Funcionários em casa (precisa VPN)
- ❌ Filiais em outras cidades

---

### 5. "Por que não sincroniza instantaneamente?"
**Resposta:** Por limitações do SQLite em rede:

- SQLite não foi feito para muitos usuários simultâneos
- A cada 10 segundos, verifica o que mudou
- Isso é um bom balanço entre velocidade e performance

**Se precisa sincronização em tempo real (< 1 segundo):**
Considere migrar para PostgreSQL (contactar desenvolvedor)

---

### 6. "E se o programa travasse durante a sincronização?"
**Resposta:** Muito improvável porque:

- A sincronização roda em **background** (não bloqueia a interface)
- Se houver erro, o programa continua funcionando
- Na próxima verificação (10 seg), tenta novamente

Se ocorrer: Aumente o intervalo para 20-30 segundos (veja `CONFIG_SINCRONIZACAO.md`)

---

### 7. "Posso desabilitar a sincronização?"
**Resposta:** ⚙️ Sim, mas não recomendado!

Se quiser desabilitar:
1. Abra `lib/shared/navigation/app_shell.dart`
2. Comente a linha: `_setupDatabaseSync();`
3. Recompile

Mas isso volta ao comportamento anterior onde era necessário sair/reentrar.

---

### 8. "Como sei que está sincronizando?"
**Resposta:** Não há indicador visual porque é automático em background.

Para **debug** (ver logs):
1. Abra `lib/core/services/database_sync_service.dart`
2. Descomente os logs
3. Veja o console do VS Code

---

### 9. "Dados podem ficar inconsistentes?"
**Resposta:** ⚡ Muito raro, mas é possível em casos extremos:

**Cenário:** Dois usuários editam o **mesmo** item simultâneamente
- A sincronização pega a versão mais recente (baseado em timestamp)
- A versão anterior é sobrescrita

**Solução:** Adicione intenção ao item (ex: "Em edição por [Usuário]")

---

### 10. "Banco de dados pode ficar corrompido?"
**Resposta:** ✅ Muito improvável. Sqlite está preparado para isso:

- Usa PRAGMA foreign_keys (integridade referencial)
- Commitmente transações ativas
- Valida dados antes de salvar

**Proteção extra:** Sempre fazer **backups regulares** (veja menu Backup do app)

---

### 11. "Posso mudar o intervalo de sincronização?"
**Resposta:** ✅ Sim!

Em `lib/app/bootstrap.dart`:
```dart
final databaseSyncService = DatabaseSyncService(
  databaseService: databaseService,
  syncIntervalSeconds: 10,  // ← Mude este número
);
```

- **5 segundos**: Mais rápido, mais CPU/memória
- **10 segundos**: Padrão (bom balanço)
- **30 segundos**: Mais lento, menos recursos

Veja `CONFIG_SINCRONIZACAO.md` para cenários específicos.

---

### 12. "Preciso configurar algo no Windows?"
**Resposta:** ✅ Se o banco está em rede:

1. **Compartilhe a pasta** com o arquivo `.sqlite`
2. **Use caminho UNC** (ex: `\\servidor\compartilhamento\banco.sqlite`)
3. Todos os PCs devem ter **acesso de leitura/escrita**

Se está em local único (um PC com HD externo):
- Apenas coloque o arquivo no caminho certo
- Pronto!

---

### 13. "E se a rede cair?"
**Resposta:** ⚠️ Se perder conexão com o arquivo SQLite:

**O que acontece:**
- Banco fica inacessível
- App pode congelar ao tentar acessar
- Erros começam a aparecer

**Solução:**
1. Reconecte a rede
2. Se problema persistir: Reinicie o app

---

### 14. "Posso usar com Google Drive / OneDrive / Dropbox?"
**Resposta:** ⚠️ **NÃO RECOMENDADO**

Esses serviços causam problemas com SQLite:
- Conflitos de sincronização
- Arquivo corrompido
- Perda de dados

**Alternativa:** Use compartilhamento de rede (SMB/NFS) ou banco de dados servidor.

---

### 15. "Quais dados ficam sincronizados?"
**Resposta:** Automaticamente sincronizam:

✅ **Sincronizados:**
- Produtos (cadastro/edição/deleção)
- Movimentos de estoque  
- Contagens de inventário
- Configurações (categorias, unidades)
- Relatórios

❓ **Parcialmente:**
- Timestamps de backup (recarregam)
- Cache de relatórios (regeneram se necessário)

---

### 16. "Há limite de tamanho de banco?"
**Resposta:** SQLite aguenta bem até:

- **1-5 usuários**: Até 100.000 produtos
- **6-10 usuários**: Até 50.000 produtos
- **10+ usuários**: Considere PostgreSQL

Se base for muito grande, considere:
- Arquivo em SSD (mais rápido)
- Verificação de integridade periódica (PRAGMA integrity_check)

---

### 17. "Posso sincronizar com múltiplos bancos?"
**Resposta:** ❌ Não. Sistema é single-database.

Se precisa múltiplos bancos (filiais):
- Cada filial tem seu banco
- Relatórios consolidados manualmente
- Ou migrar para PostgreSQL central

---

### 18. "Sincroniza backup automático?"
**Resposta:** ❌ Não.

Backups são **manuais** ou agendados, não sincronizados.

Recomendação:
1. Um usuário faz backup regularmente
2. Guarda em nuvem segura (Google Drive empresa, OneDrive, etc)
3. Documentar data/hora do backup

---

### 19. "O que fazer se sincronização não funciona?"
**Resposta:** Checklist:

1. ✅ SQLite compartilhado está acessível? (tente abrir arquivo)
2. ✅ Permissions de leitura/escrita corretas?
3. ✅ Outro programa não está bloqueando o arquivo?
4. ✅ Rede está estável?

Se ainda não funcionar:
- Aumentar `syncIntervalSeconds` para 30
- Verificar logs em `database_sync_service.dart`
- Consultar `SINCRONIZACAO.md` - Troubleshooting

---

### 20. "Posso usar em Android/iOS?"
**Resposta:** ✅ Com ressalvas:

- **Android**: ✅ Funciona em rede local
- **iOS**: ⚠️ Mais limitado (sandboxing)

Nenhum dos dois suporta acesso direto a arquivo SMB nativo. Seria necessário:
- Servidor intermediário (API)
- Ou migrar para banco de dados servidor

---

## 📞 Ainda com Dúvidas?

1. Leia `SINCRONIZACAO.md` (tecnico)
2. Veja `SINCRONIZACAO_DIAGRAMA.md` (visual)
3. Consulte `CONFIG_SINCRONIZACAO.md` (configuração)
4. Veja exemplos em `lib/core/examples/sync_example.dart`

---

**Última atualização:** 27 de março de 2026
**Versão:** 1.0
