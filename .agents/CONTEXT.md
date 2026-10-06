# 🤖 Contexto do Projeto para Agentes de IA

## 📌 Identificação do Projeto
- **Nome:** `heliomarpm/reusable-actions`
- **Repositório:** `heliomarpm/reusable-actions`
- **Propósito:** Plataforma opinativa de Reusable Workflows e Composite Actions no GitHub Actions para automação de CI, Quality Gate determinístico, Promoção Automática de Branches (Trunk, Develop, GitFlow e Hotfix), Releases SemVer nativas com changelog atômico e Publicação multi-registry.
- **Filosofia:** Alta coesão, baixo acoplamento, zero dependências externas nas engines centrais (100% Bash puro) e facilidade absoluta de consumo com poucas linhas de YAML.

---

## 🛠️ Stack e Tecnologias Centrais

| Componente | Tecnologia / Padrão | Detalhes |
| :--- | :--- | :--- |
| **Orquestração Principal** | GitHub Actions | Reusable Workflows (`workflow_call`) e Composite Actions (`using: composite`) |
| **Engines de Execução** | Bash 4+ / Shell Script | POSIX-compliant, `set -euo pipefail`, regex nativo, manipulação de streams (`sed`, `awk`, `jq`) |
| **CLI & Automações** | GitHub CLI (`gh`), Git | Autenticação via `GITHUB_TOKEN` ou `GH_TOKEN`, semântica de commits e releases |
| **Stacks Suportadas (CI/CD)** | Node.js, PHP | Node (Jest, Vitest, npm, yarn, pnpm) e PHP (Composer, PHPUnit, Pest, Clover) |
| **Stacks Planejadas** | .NET, Python, Go | Estruturas de plugins reservadas em `scripts/plugins/` |
| **Padrão de Versionamento** | Semantic Versioning (SemVer) | Conventional Commits 1.0.0 e versionamento determinístico por data/tag |

---

## 🗂️ Topologia de Pastas

```text
reusable-actions/
├── .github/workflows/         # Reusable Workflows chamados via 'uses: ...@main'
│   ├── ci-quality-gate.yml    # CI: Detecção, runtime, testes unitários, validação de cobertura
│   ├── cd-pull-request.yml    # CD: Promoção automática de branches, Auto PR com laudo de qualidade
│   ├── cd-release.yml         # CD: Release nativa com tags SemVer, notas formatadas e changelog
│   ├── cd-semantic-release.yml# CD: Semantic release avançado com plugins npm
│   ├── cd-publish.yml         # CD: Publicação multi-registry (npm, github, packagist, etc.)
│   └── changelog.yml          # Workflow de dogfooding para o próprio repositório
├── actions/                   # Composite Actions (Modo customizado/atômico)
│   ├── detect-stack/          # Auto-detecção de linguagem e runtime
│   ├── setup-runtime/         # Configuração de versão de stack e cache de pacotes
│   ├── run-tests/             # Execução de suítes de testes unitários
│   ├── run-coverage/          # Normalização de cobertura e avaliação do Quality Gate
│   ├── changelog/             # Atualização atômica do CHANGELOG.md (zero-dependency)
│   ├── release/               # Criação de Git Tag e GitHub Release oficial
│   ├── create-pr/             # Criação/atualização de PR via gh CLI com laudo injetado
│   ├── publish/               # Publicação agnóstica em um ou múltiplos registries
│   └── semantic-release/      # Wrapper para runner de semantic-release
├── scripts/
│   ├── shared/                # Lógica central em Bash puro
│   │   ├── shell-helpers.sh   # Helpers universais (log, fail, trap on_error, render_template)
│   │   ├── detect-stack.sh    # Algoritmo de identificação de stack
│   │   ├── changelog/run.sh   # Engine de extração de commits e formatação de changelog
│   │   ├── release/run.sh     # Engine de bump de versão, tags e releases
│   │   ├── publish/run.sh     # Engine de publicação sequencial multi-registry
│   │   └── semantic-release/  # Scripts de suporte e plugins do semantic-release
│   └── plugins/               # Extensões isoladas por linguagem
│       ├── node/              # Node.js: install-deps, test, coverage, publish, releaserc
│       ├── php/               # PHP: install-deps, test, coverage, publish, releaserc
│       ├── dotnet/            # .NET: (Planejado)
│       ├── python/            # Python: (Planejado)
│       └── go/                # Go: (Planejado)
├── templates/                 # 17 templates Markdown (PR body, summaries de CI/CD, STRICT MODE)
├── docs/                      # Documentação comunitária e ADRs
│   ├── CODE_OF_CONDUCT.md     # Código de Conduta (pt-BR)
│   ├── CONTRIBUTING.md        # Guia de Contribuição (pt-BR)
│   ├── SUPPORT.md             # Guia de Suporte (pt-BR)
│   └── adrs/                  # Architecture Decision Records canônicos (ADR-001 a ADR-003)
├── .agents/                   # Memória técnica, arquitetura e contexto para Agentes de IA
│   ├── ARCHITECTURE.md        # Arquitetura detalhada para mantenedores e IAs
│   ├── CONTEXT.md             # Este documento executivo
│   ├── AGENTS.md              # Regras de ouro e restrições estritas para IAs
│   └── DATA.md                # Fluxo de dados, contratos de estado e integrações
└── TODO.md                    # Roadmap e backlog de desenvolvimento
```

---

## ⚡ Comandos Essenciais de Verificação

```bash
# Validar sintaxe de todos os scripts bash
Get-ChildItem -Path scripts -Recurse -Filter *.sh | ForEach-Object { $rel = (Resolve-Path -Relative $_.FullName).Replace('\', '/'); bash -n "$rel" }

# Verificar status do git e codificação
git status --short
```

---

## ⚠️ Regras Mandatórias de Engenharia

1. **Controle de Versão Git:**
   - **NUNCA** executar `git push`, `git commit` ou criar tags remotas sem autorização explícita do usuário.
   - Sempre respeitar a integridade de codificação UTF-8 no Windows/PowerShell.
2. **Scripts Bash:**
   - Todo script deve passar na validação de sintaxe: `bash -n <script>`.
   - Utilizar sempre `set -euo pipefail`.
   - Evitar ferramentas pesadas externas; privilegiar Bash nativo e ferramentas pré-instaladas no runner (`jq`, `git`, `gh`, `sed`, `awk`).
3. **Consumo Amigável:**
   - O `README.md` deve ser 100% voltado para desenvolvedores consumidores da lib.
   - Detalhes de implementação e arquitetura devem ser mantidos em `.agents/` ou `docs/adrs/`.
