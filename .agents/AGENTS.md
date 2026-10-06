# 🤖 Diretrizes e Regras de Ouro para Agentes de IA (AGENTS.md)

Instruções mandatórias que qualquer agente de IA ou desenvolvedor automatizado deve seguir estritamente ao propor ou alterar código neste repositório:

---

## 1. 🛡️ Segurança Git e Manipulação de Repositório

1. **Operações Remotas Proibidas sem Permissão**:
   - NUNCA execute `git push`, `git push --tags`, `git commit` ou crie branches remotas sem consentimento explícito e direto do usuário.
   - NUNCA execute `git reset --hard` ou operações destrutivas no histórico local sem confirmação.
2. **Higiene de Codificação e Encodings**:
   - Todas as modificações em arquivos Markdown, Bash e YAML devem manter codificação **UTF-8 sem BOM**.
   - Em ambiente Windows / PowerShell, garanta que quebras de linha (`LF` nos scripts `.sh`) sejam preservadas para que a execução no runner Linux (`ubuntu-latest`) não falhe por caracteres `\r`.

---

## 2. 🐚 Padrões de Scripts Bash

1. **Modo Estrito Obrigatório**:
   - Todo script shell (`.sh`) deve iniciar com `#!/usr/bin/env bash` seguido de `set -euo pipefail`.
2. **Reaproveitamento de Helpers Universais**:
   - Utilize as funções compartilhadas de `scripts/shared/shell-helpers.sh`:
     - `log "mensagem"` para logs formatados no stderr.
     - `fail "mensagem"` para anotações `::error::` e encerramento com código `1`.
     - `validate_git_repository` para checagem de repositório e alerta de shallow clone.
     - `render_template` e `append_template_to_summary` para manipular templates Markdown em `templates/`.
3. **Validação Prévia de Sintaxe**:
   - Antes de concluir qualquer tarefa envolvendo scripts, valide a sintaxe com `bash -n <arquivo.sh>`.
4. **Isolamento de Processos**:
   - Variáveis temporárias devem ser criadas via `mktemp` ou direcionadas a `${RUNNER_TEMP:-/tmp}`, limpando-as via `trap` ao término da execução.

---

## 3. ⚙️ Padrões de Composite Actions e Workflows

1. **Separação de Camadas (ADR-002)**:
   - **Camada 1 (Reusable Workflows)**: Residem em `.github/workflows/`. Cuidam de orquestração de alto nível, download de código, permissões do GitHub token e condicionais de branch.
   - **Camada 2 (Composite Actions)**: Residem em `actions/<nome>/`. Devem ser atômicas, agnósticas e reutilizáveis em qualquer workflow customizado.
   - **Camada 3 (Engines em Bash)**: Residem em `scripts/`. Contêm a lógica pesada de parsing, regex e execução.
2. **Nomenclatura de Inputs e Outputs**:
   - Todos os inputs e outputs de actions devem seguir o padrão `kebab-case` (ex: `project-path`, `coverage-min`, `has-changes`).
3. **Resolução de Caminhos**:
   - Nas composite actions, sempre defina `REUSABLE_PATH: ${{ github.action_path }}/../..` e `BASH_ENV: ${{ github.action_path }}/../../scripts/shared/shell-helpers.sh` para que os scripts encontrem os helpers independentemente do diretório de execução do runner.
4. **Versão de Actions Terceiras**:
   - Utilize sempre versões válidas e estáveis das ações oficiais do GitHub (`actions/checkout@v4`, `actions/setup-node@v4`).

---

## 4. 📝 Governança de Commits e Documentação

1. **Conventional Commits**:
   - Todo commit deve seguir rigorosamente o padrão Conventional Commits 1.0.0 (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `ci:`, `test:`, `perf:`).
   - Commits de quebra de compatibilidade devem conter `!` após o tipo/escopo ou `BREAKING CHANGE:` no rodapé.
2. **Separação de Documentação (Consumidor vs Interno)**:
   - O [README.md](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/README.md) principal é destinado exclusivamente aos desenvolvedores consumidores da biblioteca (foco em uso, exemplos em 3 minutos e inputs).
   - Documentações técnicas de arquitetura interna, ADRs e guias de manutenção pertencem a [.agents/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/.agents/) e [docs/adrs/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/docs/adrs/).
