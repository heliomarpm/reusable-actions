# 🤖 Contexto do Projeto para Agentes de IA

## 📌 Identificação do Projeto
- **Nome:** `heliomarpm/reusable-actions`
- **Propósito:** Plataforma unificada de Reusable Workflows e Composite Actions para automação de CI, Quality Gate, Auto PR (GitFlow/Trunk), Release determinística e Publicação multi-registry.
- **Filosofia:** Alta coesão, baixo acoplamento, zero dependências externas nos fluxos nativos e facilidade absoluta de consumo via GitHub Actions.

---

## 🗂️ Estrutura Resumida
```
reusable-actions/
├── .github/workflows/         # Reusable Workflows (Chamados via 'uses: ...@main')
│   ├── ci-quality-gate.yml    # CI: Detecção, runtime, testes, cobertura
│   ├── cd-pull-request.yml    # CD: Promoção e abertura de PRs automáticos
│   ├── cd-release.yml         # CD: Release nativa com tags, notas e changelog opcional
│   ├── cd-semantic-release.yml# CD: Semantic release com plugins npm
│   └── cd-publish.yml         # CD: Publicação multi-registry (npm, github, etc.)
├── actions/                   # Composite Actions (Modo customizado)
│   ├── detect-stack/          # Auto-detecção de tecnologia
│   ├── setup-runtime/         # Configuração de versão/cache
│   ├── run-tests/             # Execução de suítes de teste
│   ├── run-coverage/          # Cálculo e normalização de cobertura
│   ├── changelog/             # Atualização atômica do CHANGELOG.md
│   ├── release/               # Criação de Git Tag e GitHub Release
│   ├── create-pr/             # Criação/atualização de PR via gh CLI
│   ├── publish/               # Publicação agnóstica em registries
│   └── semantic-release/      # Wrapper para semantic-release CLI
├── scripts/
│   ├── shared/                # Lógica central em Bash
│   │   ├── shell-helpers.sh   # Helpers universais (log, fail, validate_git)
│   │   ├── detect-stack.sh    # Regras de detecção de linguagem
│   │   └── .../run.sh         # Executores das actions
│   └── plugins/               # Extensões por linguagem
│       ├── node/              # Node.js: Jest/Vitest, NPM/Yarn/PNPM, releaserc
│       └── php/               # PHP: Composer, PHPUnit/Pest, Packagist
├── templates/                 # Modelos Markdown de PR e resumos
├── docs/adrs/                 # Architecture Decision Records
└── .agents/                   # Documentação técnica para IAs
```

---

## ⚠️ Regras Mandatórias de Engenharia
1. **Controle de Versão Git:**
   - **NUNCA** executar `git push`, `git commit` ou `git pull` sem consentimento explícito do usuário.
   - Sempre respeitar a integridade de codificação UTF-8 no Windows/PowerShell.
2. **Bash Scripts:**
   - Todo script deve passar na validação de sintaxe: `bash -n <script>`.
   - Utilizar sempre `set -Eeuo pipefail`.
3. **Consumo Amigável:**
   - O `README.md` deve ser 100% voltado para desenvolvedores consumidores da lib.
   - Detalhes de implementação e arquitetura devem ser mantidos em `.agents/` ou `docs/adrs/`.
