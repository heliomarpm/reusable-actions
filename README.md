# 🚀 Reusable Actions — CI, Auto PR & Semantic Release

Conjunto de GitHub Actions (Reusable Workflows e Composite Actions) para padronizar CI, cobertura, promoção de código e releases automatizados, com suporte a múltiplas stacks e foco em escalabilidade.

## 🧠 Filosofia

> "Automação sem disciplina cria caos. \
> Disciplina sem automação não escala."

Este projeto foi reestruturado (ADR-002) para oferecer dois níveis de uso:
- **Nível Quick**: Reusable Workflows prontos que orquestram o pipeline inteiro.
- **Nível Custom**: Composite Actions granulares (blocos atômicos) para montar seu próprio pipeline.

## 🎯 Objetivos

- Reduzir boilerplate em pipelines
- Padronizar versionamento com `semantic-release`
- Garantir qualidade mínima com **STRICT MODE** e **Quality Gate**
- Permitir evolução por stack sem acoplamento (PHP, Node.js implementados)
- Estratégias de promoção de branch claras (`trunk`, `develop`, `gitflow`)

---

## 🏗 Estratégias de Promoção e Fluxo de Branches

A action de promoção (`cd-pull-request.yml`) suporta três estratégias consolidadas para controle do seu fluxo de código. Você escolhe a estratégia através do input `strategy`.

| Estratégia | Fluxo | Quando promove automaticamente |
| :--- | :--- | :--- |
| **`trunk`** | `feature/**` → `main` | Imediatamente (sempre) |
| **`develop`** | `feature/**` → `develop` → `main` | Apenas quando detecta nova versão via Semantic Release |
| **`gitflow`** | `feature/**` → `develop` → `release-x.y.z` → `main` | Apenas quando detecta nova versão via Semantic Release |

### 🔥 Hotfix (O Override Controlado)

Branches prefixadas com `hotfix/*` são a exceção arquitetural controlada. Elas ignoram a estratégia atual e **sempre abrem PR diretamente para a branch principal (`main`)**. Isso garante velocidade e segurança na resposta a incidentes de produção, sem passar pela branch de desenvolvimento.

---

## 📦 Workflows Disponíveis (Modo Quick)

### 1️⃣ CI — Quality Gate (Testes e Cobertura)

Este workflow detecta a stack do seu projeto, configura o runtime, executa os testes e normaliza a cobertura, atuando como o **Juiz Único** da qualidade do código.

```yaml
name: "1. Quality Assurance"

on:
  push:
    branches: ["develop", "feature/**", "hotfix/**"]

jobs:
  qa:
    uses: heliomarpm/reusable-actions/.github/workflows/ci-quality-gate.yml@main
    with:
      coverage-min: 85
      coverage-mode: block # 'block' falha o job se cobertura < 85%. 'info' apenas emite alertas. 'decrease' falha se cobertura diminuir desde o ultimo merge
```

**Inputs principais:** `stack`, `project-path`, `coverage-min` (padrão: 80), `coverage-mode` (`info` | `block` | `decrease`).

---

### 2️⃣ CD — Promoção Automática de Branches (Auto PR)

Orquestra a estratégia escolhida (`trunk`, `develop` ou `gitflow`) e cria ou atualiza o Pull Request automaticamente.

> 💡 **Single Source of Truth (SSOT):** O Auto PR **não** requer parâmetros de cobertura (`min-coverage` ou `coverage-mode`). Ele consome automaticamente o laudo já avaliado pelo Quality Gate, aplicando as labels (`coverage-passed`, `coverage-failed`) e formatando a tabela no corpo do PR!

```yaml
name: "2. Auto PR"

on:
  workflow_run:
    workflows: ["1. Quality Assurance"]
    types:
      - completed

jobs:
  promote:
    # ⚠️ IMPORTANTE: Garante que a PR SÓ será aberta se o Quality Assurance PASSOU!
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    uses: heliomarpm/reusable-actions/.github/workflows/cd-pull-request.yml@main
    with:
      strategy: develop # trunk | develop | gitflow
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### 🛡️ Como Funciona o Bloqueio por Cobertura Mínima

O controle de qualidade segue o princípio de **separação de responsabilidades**:

```
[ Push no Código ]
       │
       ▼
┌─────────────────────────────────┐
│     1. Quality Assurance        │
│                                 │
│  • Executa testes unitários     │
│  • Calcula cobertura (ex: 78%)  │
│  • coverage-min: 85             │
│  • coverage-mode: block         │
└────────────────┬────────────────┘
                 │
       ┌─────────┴─────────┐
       │ Cobertura < 85%?  │
       └─────────┬─────────┘
                 │
        ┌────────┴────────┐
        │                 │
     Sim (FALHA)       Não (SUCESSO)
        │                 │
        ▼                 ▼
 🚫 Job Cancelado   ✅ Dispara: 2. Auto PR
 (PR NUNCA abre!)   (Abre PR com tabela de métricas)
```

1. **Modo `block` no Quality Gate:**  
   Se você definir `coverage-mode: block` no CI e a cobertura ficar abaixo de `coverage-min`, o job do CI **falha com erro vermelho**.
2. **Condição no Auto PR:**  
   Como o workflow de PR contém a cláusula:
   ```yaml
   if: ${{ github.event.workflow_run.conclusion == 'success' }}
   ```
   Ele **não é executado** caso o CI tenha falhado. A criação do Pull Request é bloqueada logo na entrada!
3. **Modo `info` (Informativo):**  
   Se usar `coverage-mode: info`, o CI sempre passará com sucesso. O PR será aberto normalmente, mas exibirá o status `failed` e a etiqueta vermelha `coverage-failed` como feedback visual para os revisores.

---

### 3️⃣ CD — Semantic Release

Workflow unificado de execução final do Release baseado nas mensagens de commit convencionais ao mergir na `main`.

---

## 🔧 Composite Actions (Modo Custom)

Se você preferir construir seu próprio fluxo, este repositório exporta as ações unitárias (localizadas na pasta `/actions/`):

- `heliomarpm/reusable-actions/actions/detect-stack@main`
- `heliomarpm/reusable-actions/actions/setup-runtime@main`
- `heliomarpm/reusable-actions/actions/run-tests@main`
- `heliomarpm/reusable-actions/actions/run-coverage@main`
- `heliomarpm/reusable-actions/actions/semantic-release@main`
- `heliomarpm/reusable-actions/actions/create-pr@main`

**Exemplo Prático (Custom Pipeline):**
```yaml
jobs:
  custom-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - id: stack
        uses: heliomarpm/reusable-actions/actions/detect-stack@main
      - uses: heliomarpm/reusable-actions/actions/setup-runtime@main
        with:
          stack: ${{ steps.stack.outputs.stack }}
      - uses: heliomarpm/reusable-actions/actions/run-coverage@main
        with:
          stack: ${{ steps.stack.outputs.stack }}
          coverage-min: 85
          coverage-mode: block
```

---

## 🔒 STRICT MODE — Commits Convencionais

Opção habilitada por padrão (`strict_conventional_commits: true`).
Ela **bloqueia as releases** silenciosamente erradas, forçando que todos os commits promovidos para a master sigam o padrão *Conventional Commits*. 
Isso adiciona Annotations visíveis no GitHub e orienta o time com um Summary rico, caso haja erros no padrão.

---

## 🧱 Stacks Suportadas

- ✅ Node.js (Suporte a Jest/Vitest, NPM/Yarn/PNPM)
- ✅ PHP (Suporte a PHPUnit/Pest, Cobertura em Clover)
- 🚧 .NET (Prioridade futura)
- 🚧 Python (Prioridade futura)
- 🚧 Go (Prioridade futura)

Cada stack isola seus próprios scripts de dependência em `scripts/plugins/<stack>`, sendo chamadas automaticamente pelas Actions com base no repositório consumidor.

---

## 📝 Contribuições e Roadmap

- O projeto está em fase `main` e será promovido para versão `v1` assim que a fase de testes internos terminar.
- Veja nosso [TODO.md](TODO.md) para o roadmap.
- Veja os Arquivos [ADR](docs/adrs) para o histórico de decisões da arquitetura.

### ❤️ Apoie este projeto

Se este projeto lhe foi útil de alguma forma:
⭐ Adicione o repositório aos seus favoritos \
🐞 Reporte erros \
💵 [Apoie no GitHub Sponsors](https://github.com/sponsors/heliomarpm)

## 📝 Licença
[MIT © Heliomar P. Marques](LICENSE)
