# 🧠 Arquitetura Técnica Interna — Reusable Workflows

> **Público-alvo:** Mantenedores do projeto, contribuidores de core e Agentes de IA.  
> Este documento concentra o funcionamento técnico detalhado, decisões de arquitetura e mecânica interna dos scripts e ações, mantendo o `README.md` principal 100% focado no usuário consumidor.

---

## 🏛️ Visão Geral da Arquitetura

O ecossistema é dividido em duas camadas estritas (conforme formalizado na **ADR-002**):

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Camada 1: Reusable Workflows                         │
│   (.github/workflows/*.yml - ci-quality-gate, cd-pull-request, etc.)   │
│   • Orquestram o fluxo de ponta a ponta.                               │
│   • Cuidam de checkout, download de artefatos, condicionais de branch. │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ consome
┌───────────────────────────────────▼────────────────────────────────────┐
│                    Camada 2: Composite Actions                         │
│                    (actions/<nome>/action.yml)                         │
│   • Blocos atômicos e agnósticos.                                      │
│   • Invocam scripts em scripts/shared/ ou scripts/plugins/.            │
│   • Zero acoplamento entre si.                                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ executa
┌───────────────────────────────────▼────────────────────────────────────┐
│                      Camada 3: Scripts Bash                            │
│                 (scripts/shared/ e scripts/plugins/)                   │
│   • Lógica determinística em Bash puro (POSIX-compliant com set -euo). │
│   • Helpers compartilhados em scripts/shared/shell-helpers.sh.         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 Mapeamento de Pastas e Componentes

| Diretório | Responsabilidade |
| :--- | :--- |
| `.github/workflows/` | **Reusable Workflows** (`cd-pull-request.yml`, `cd-release.yml`, `cd-semantic-release.yml`, `cd-publish.yml`). |
| `actions/` | **Composite Actions** atômicas prontas para consumo direto em pipelines customizados. |
| `scripts/shared/` | Engines centrais escritas em Bash (shell helpers, detect-stack, parser de commits, run.sh das actions). |
| `scripts/plugins/<stack>/` | Plugins especializados por linguagem (`node`, `php`). Contém scripts de teste, cobertura, build e publish. |
| `templates/` | Modelos em Markdown para PR body, step summaries de sucesso/falha e avisos de STRICT MODE. |
| `docs/adrs/` | Architecture Decision Records canônicos (ADR-001 a ADR-003). |
| `.agents/` | Contexto, guias técnicos e base de conhecimento para Agentes de IA. |

---

## 🔍 Detalhamento das Engines Internas

### 1. Engine de Quality Gate e Cobertura (`actions/run-coverage`)
- **Normalização de Cobertura:** Os plugins de stack geram formatos nativos (ex: LCOV para Jest/Vitest no Node, Clover XML para PHPUnit/Pest no PHP).
- **Extração Agnóstica:** O script `scripts/shared/coverage-engine.sh` processa o arquivo gerado e produz um JSON unificado:
  `coverage/coverage-summary.normalized.json` contendo:
  ```json
  {
    "line": 85.5,
    "min": 80.0,
    "status": "passed",
    "mode": "block"
  }
  ```
- **Single Source of Truth (SSOT):** O workflow unificado `cd-pull-request.yml` avalia os critérios (`block`, `info`, `decrease`) e injeta o status de cobertura diretamente como input para o job subsequente que abre o Pull Request, garantindo agilidade e coesão na mesma pipeline.

---

### 2. Engine de Promoção Automática de Branches (`cd-pull-request.yml`)
- **Resolução de Branches (`resolve` job):**
  Identifica a branch de origem (`HEAD`) e determina o destino (`BASE`) através de um case determinístico:
  - `trunk`: `feature/**` → `main`
  - `develop`: `feature/**` → `develop`; se `develop` → avalia se gera versão e promove para `main`.
  - `gitflow`: `feature/**` → `develop`; se `develop` → avalia versão e promove para `release-x.y.z`; se `release-x.y.z` → promove para `main`.
  - `hotfix`: `hotfix/**` → intercepta imediatamente e direciona para `main`.
- **Execução Nativa e Segura:**
  O evento inicia diretamente via `push` ou `pull_request` no contexto da branch em alteração (`github.head_ref`). O checkout recebe a referência atualizada (`ref: ${{ needs.resolve.outputs.head }}`) com `fetch-depth: 0` para garantir validação e auto-promoção confiáveis.
- **Skip Gracioso:**
  Se não houver novos commits de versão em `develop`, o workflow emite um notice amigável e define `skip=true`, finalizando a execução verde (`exit 0`) sem abrir PRs vazios.

---

### 3. Engine de Changelog Nativo (`actions/changelog` e `scripts/shared/changelog/run.sh`)
- **Zero Dependências:** 100% Bash puro, dispensando pacotes npm ou ferramentas externas.
- **Parser de Commits Robusto:**
  Utiliza os caracteres delimitadores ASCII `0x1f` (Unit Separator) e `0x1e` (Record Separator) em `git log --pretty=format:"%H%x1f%h%x1f%s%x1f%b%x1e"` para evitar quebras por quebras de linha em commits com corpos extensos.
- **Ciclo de Vida `[Unreleased]`:**
  - Em branches como `develop`, insere ou substitui a seção `## [Unreleased]`.
  - Em branches de release (`main`), converte o conteúdo de `[Unreleased]` em uma versão definitiva com data, limpando a seção unreleased atomicamente via `awk`.
- **Foco Único:** Apenas lê commits, formata Markdown e comita no `CHANGELOG.md`. Não cria tags nem releases.

---

### 4. Engine de Release Nativa (`actions/release` e `scripts/shared/release/run.sh`)
- **Foco Único:** Criação de Git Tag anotada (`git tag -a`) e GitHub Release oficial via GitHub CLI (`gh release create`).
- **Resolução de Versão Flexível:**
  - Se receber `version` e `release-notes` pré-calculadas pelo step de changelog, reaproveita-as diretamente.
  - Se acionada isoladamente, analisa os commits desde a última tag, calcula o bump SemVer e gera notas categorizadas com emojis convertidos.
- **Apenas Branches Autorizadas:** Executa exclusivamente em `RELEASE_BRANCHES` (`main`, `master`). Em branches secundárias, encerra com sucesso sem tocar em tags remotas.

---

### 5. Engine de Publicação Multi-Registry (`actions/publish` e `scripts/shared/publish/run.sh`)
- **Matriz de Execução Paralela:** Recebe `registries: 'npm, github'` (separados por vírgula), converte-os em um Array JSON e utiliza GitHub Actions `strategy.matrix` para paralelisar a publicação com eficiência máxima.
- **Isolamento de Credenciais:**
  - Configura temporariamente o arquivo `.npmrc` com o token e registry específicos do job corrente na matriz.
  - O isolamento do runner previne vazamento de estado.
- **Auto-Scoping no Node.js para GitHub Packages:**
  O GitHub Packages exige que pacotes npm sejam escopados com o usuário/organização (`@owner/nome`). Caso o `package.json` possua nome não escopado (ex: `"minha-lib"`), o script temporariamente injeta `@${OWNER}/minha-lib` durante o upload para o GitHub Packages e restaura o `package.json` original logo após a publicação via `trap`.
- **Relatório Paralelizado:** Escreve tabela Markdown no resumo do job específico da matriz com o status da publicação na plataforma destino.

---

## 🛠️ Padrões de Código e Diretrizes para Modificações

1. **Scripts Bash:**
   - Sempre declarar `set -Eeuo pipefail` no início.
   - Carregar e utilizar helpers padrão de `scripts/shared/shell-helpers.sh` (`log`, `fail`, `validate_git_repository`, etc.).
   - Sempre verificar a sintaxe via `bash -n <script>` antes de concluir qualquer alteração.
2. **Composite Actions:**
   - Utilizar identificadores de inputs em `kebab-case`.
   - Sempre exportar `REUSABLE_PATH: ${{ github.action_path }}/../..` para garantir que scripts aninhados localizem a raiz do projeto.
   - Sempre exportar `BASH_ENV` apontando para `shell-helpers.sh`.
3. **Reusable Workflows:**
   - Definir permissões mínimas explícitas em nível de workflow ou job.
   - Sempre utilizar defaults seguros em `workflow_call`.
