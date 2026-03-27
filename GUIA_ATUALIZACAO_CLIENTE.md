# 📦 GUIA DE ATUALIZAÇÃO PARA CLIENTES

## ✅ É SEGURO ATUALIZAR?

**SIM!** A atualização é 100% segura porque:

✅ **Nenhuma alteração no banco de dados**
- Não adiciona tabelas novas
- Não modifica estrutura existente
- Dados antigos são preservados

✅ **Suporte automático de migração**
- SQLite já suporta migrations
- Upgrades de versão são automáticos
- Backup recomendado como precaução

---

## 📋 PRÉ-REQUISITOS

Antes de atualizar, verifique:

1. ✅ Todos os usuários saíram do programa
2. ✅ Nenhuma janela do StokEasy está aberta
3. ✅ Banco de dados está acessível em rede (se compartilhado)
4. ✅ Permissões de leitura/escrita estão OK

---

## 🔄 PROCESSO DE ATUALIZAÇÃO

### Opção 1: Atualização Simples (Recomendado para Pequenas Equipes)

**Passo 1: Fazer backup**
```
1. Abra o StokEasy
2. Menu > Configurações > Backup
3. Clique em "Fazer Backup"
4. Salve em local seguro (Google Drive, USB, etc)
```

**Passo 2: Atualizar o app**
```
1. Feche completamente o StokEasy em todos os computadores
2. Substitua os arquivos do app pela nova versão
   - Se Windows: Copie os arquivos de instalação
   - Se entregue por email: Extraia o .zip novo
3. Abra o app novamente
```

**Passo 3: Verificar**
```
1. Abra o StokEasy
2. Verifique se:
   ✅ Todos os produtos aparecem
   ✅ Todos os movimentos aparecem
   ✅ Categorias estão OK
   ✅ Sync automático está funcionando (~10 seg)
```

### Opção 2: Atualização em Rede Compartilhada

**Se o banco está em \\servidor\compartilhamento\banco.sqlite:**

**Passo 1: Backup do banco**
```
1. Copie o arquivo 'stokeasy.sqlite' para:
   \\servidor\backup\stokeasy_backup_[data].sqlite
   
   Exemplo:
   \\servidor\backup\stokeasy_backup_20260327.sqlite
```

**Passo 2: Atualizar todos os computadores**
```
1. Em CADA computador (um por vez):
   - Feche o StokEasy completamente
   - Substitua o app pela nova versão
   - Abra novamente

2. Teste que o primeiro PC funciona bem
3. Depois atualiza os outros
```

**Passo 3: Teste de sincronização**
```
1. Em PC 1: Adicione um produto teste
2. Aguarde 10-15 segundos
3. Em PC 2: Verifique se o produto aparece
   - Se SIM: ✅ Sincronização está funcionando!
   - Se NÃO: Veja troubleshooting abaixo
```

---

## ⚠️ O QUE NÃO SERÁ AFETADO

✅ Todos os dados serão preservados:
- Produtos cadastrados
- Movimentos de estoque
- Histórico de contagens
- Configurações (categorias, unidades)
- Backups anteriores

❌ Nada será deletado ou modificado!

---

## 🧪 VERIFICAÇÃO PÓS-ATUALIZAÇÃO

Após atualizar, verifique:

### 1️⃣ Dados Intactos
```
□ Produtos ainda aparecem
□ Quantidades estão corretas
□ Movimentos ainda visíveis
□ Categorias e unidades OK
```

### 2️⃣ Sincronização Funcionando
```
□ PC 1 adiciona produto
□ Aguarda 10 segundos
□ PC 2 vê o novo produto automaticamente
□ Sem necessidade de sair/reentrar
```

### 3️⃣ Performance
```
□ App abre rapidamente
□ Listas carregam OK
□ Sem travamentos
□ Interface responsiva
```

---

## 🆘 SE ALGO DER ERRADO

### Problema: "Dados sumiram!"

**Solução:**
```
1. NÃO FAÇA NADA IMPORTANTE
2. Restaure de um dos backups:
   - Menu > Configurações > Restaurar Backup
   - Selecione o backup mais recente
3. Tente novamente
```

### Problema: "Sincronização não funciona"

**Verificação:**
```
1. Banco SQLite está acessível?
   - Teste: consegue abrindo o arquivo
   - Tem permissão de leitura/escrita?

2. Rede está estável?
   - Ping para o servidor
   - Reconecte se necessário

3. Aguarde 30 segundos:
   - Às vezes demora na primeira vez

Se não funcionar:
   - Contacte o suporte
   - Forneça arquivo de log (se disponível)
```

### Problema: "Banco diz que está usando versão diferente"

**Solução:**
```
1. Isso é normal após atualizar
2. SQLite detecta versão nova do app
3. Migração automática é executada
4. Pode levar uns segundos (1-2 min em bancos grandes)
5. Deixe terminar sem interromper!
```

### Problema: "Dois computadores conflitam"

**Solução:**
```
1. Feche AMBOS os computadores
2. Aguarde 30 segundos
3. Abra um por vez, a cada 2 minutos
4. Deixe o primeiro sincronizar completamente
5. Depois abre o segundo
```

---

## 📊 COMPARAÇÃO: ANTES vs. DEPOIS

| Comportamento | Antes | Depois |
|---|---|---|
| Alguém muda algo | ❌ Você não vê | ✅ Você vê em ~10 seg |
| Precisa sair/reentrar? | ❌ SIM (necessário) | ✅ NÃO (automático) |
| Dados intactos? | ✅ SIM | ✅ SIM |
| Performance | ✅ Rápido | ✅ Igual |
| Sincronização | ❌ Manual | ✅ Automática |

---

## 💾 ESTRATÉGIA DE BACKUP RECOMENDADA

### Antes de atualizar:
```
1. Fazer backup pelo app (Menu > Backup)
2. Salvar em 2 lugares:
   - Dentro do computador
   - Na nuvem (Google Drive, OneDrive, etc)
```

### Depois de atualizar:
```
1. Testar tudo funciona bem
2. Fazer um novo backup
3. Guardar backup antigo por 30 dias
   (em caso de problema inesperado)
```

---

## 📝 CHECKLIST FINAL

Antes de liberar a atualização aos clientes:

- ✅ Versão de teste instalada em seu PC
- ✅ Todos dados intactos após atualizar
- ✅ Sincronização testada com 2+ PCs
- ✅ Backups funcionalidades OK
- ✅ Menu Help/Suporte sabe sobre a mudança
- ✅ Documentação (este arquivo) é conhecida pelos clientes

---

## 📞 SUPORTE

Se tiver dúvidas:

1. **Leia `PARA_O_CLIENTE.txt`** - Resumo da nova feature
2. **Veja `FAQ_SINCRONIZACAO.md`** - Perguntas comuns
3. **Contacte desenvolvimento** - Se erro persistir

---

**Status:** ✅ Seguro para atualizar
**Risco:** Muito baixo (dados não são alterados)
**Duração:** 5-15 minutos por cliente
**Data desta versão:** 27/03/2026
