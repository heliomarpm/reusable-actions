<div id="top" align="center">
  <h1>🚀 Reusable Workflows — CI/CD Sem Boilerplate no GitHub Actions <a href="https://navto.me/heliomarpm" target="_blank"><img src="https://navto.me/assets/navigatetome-brand.png" width="32"/></a></h1>

  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF.svg?logo=githubactions&logoColor=white)](https://github.com/features/actions)
  [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
  [![Node.js](https://img.shields.io/badge/Node.js-18%20|%2020%20|%2022-brightgreen.svg?logo=node.js)](https://nodejs.org)
  [![PHP](https://img.shields.io/badge/PHP-8.1%20|%208.2%20|%208.3-8892BF.svg?logo=php&logoColor=white)](https://php.net)


  <div class="badges">

  [![GitHub Sponsors][url-github-sponsors-badge]][url-github-sponsors]
  [![PayPal][url-paypal-badge]][url-paypal]
  [![Ko-fi][url-kofi-badge]][url-kofi]
  [![Liberapay][url-liberapay-badge]][url-liberapay]
    
  </div>
</div>

**Reusable Workflows** é um conjunto opinativo de **Reusable Workflows** e **Composite Actions** projetado para padronizar e acelerar esteiras de integração contínua (CI), controle de qualidade, promoção automática de branches e releases no GitHub Actions.

Com apenas algumas linhas de YAML, qualquer repositório herda:
- 🧪 **Quality Gate determinístico**: execução de testes e validação rigorosa de cobertura mínima.
- 🔀 **Promoção Automática de Branches (Auto PR)**: suporte nativo a estratégias **Trunk-Based**, **Develop** e **GitFlow** (com suporte a hotfixes emergenciais).
- 🏷️ **Releases e Changelog Automatizados**: versionamento semântico determinístico com zero dependências externas.
- 📦 **Publicação Multi-Registry**: publicação simultânea de pacotes para múltiplos registries (ex: `npm` e `GitHub Packages` no mesmo ciclo).

## 🧠 Filosofia

> "Automação sem disciplina cria caos. \
> Disciplina sem automação não escala."

---

## 📣 Por que isso existe

A maioria dos repositórios começa simples e gradualmente acumula complexidade operacional:

- Pipelines de CI inconsistentes
- Releases manuais
- Versionamento não confiável
- Regras de promoção de branches pouco claras
- Verificações de qualidade aplicadas tardiamente

Grandes empresas resolvem isso com equipes de engenharia de plataforma.

Equipes pequenas e desenvolvedores individuais geralmente não conseguem.

Este projeto codifica um modelo mínimo de engenharia de plataforma em fluxos de trabalho reutilizáveis para que cada repositório possa começar com práticas de engenharia previsíveis desde o primeiro dia.

### O que este projeto é

Uma plataforma de fluxo de trabalho reutilizável que fornece:

- Releases determinísticos
- Controles de qualidade rigorosos
- Estratégia de promoção consistente
- Governança de commits convencional
- Execução agnóstica à stack de tecnologias

Você adiciona fluxos de trabalho.

Você herda a disciplina de engenharia.

---

## O que este projeto NÃO é

- um kit de ferramentas de CI genérico
- um repositório de modelos
- um framework DevOps completo
- pipelines infinitamente configuráveis

O projeto é intencionalmente opinativo.

Os valores padrão fazem parte do seu valor.

--- 

## ⚡ Quick Start em 3 Minutos

Para habilitar a esteira completa no seu repositório consumidor, crie os três arquivos abaixo na pasta `.github/workflows/`:

### 1. `.github/workflows/ci.yml` — Validação de Qualidade
Executa testes e calcula a cobertura a cada commit enviado:

```yaml
name: "1. Quality Assurance"

on:
  push:
    branches: ["develop", "feature/**", "hotfix/**", "release-*"]

jobs:
  qa:
    uses: heliomarpm/reusable-workflows/.github/workflows/ci-quality-gate.yml@main
    with:
      coverage-min: 80
      coverage-mode: block # 'block' falha o job se cobertura < 80%. 'info' apenas emite alertas.
```

### 2. `.github/workflows/auto-pr.yml` — Promoção Automática
Disparado assim que o CI é concluído com sucesso, abrindo ou atualizando o Pull Request de acordo com o fluxo do seu time:

```yaml
name: "2. Auto PR"
run-name: "🔀 Auto PR: ${{ github.event.workflow_run.head_branch }} → ${{ github.event.workflow_run.head_branch == 'develop' && 'main' || 'develop' }}"

on:
  workflow_run:
    workflows: ["1. Quality Assurance"]
    types: [completed]

jobs:
  promote:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    uses: heliomarpm/reusable-workflows/.github/workflows/cd-pull-request.yml@main
    with:
      strategy: develop # Opções: trunk | develop | gitflow
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3. `.github/workflows/release.yml` — Criação da Release
Gera a Git Tag, notas categorizadas e atualiza o `CHANGELOG.md` automaticamente ao integrar na branch principal:

```yaml
name: "3. Release"

on:
  push:
    branches: [main]
    paths-ignore:
      - 'CHANGELOG.md'

jobs:
  release:
    uses: heliomarpm/reusable-workflows/.github/workflows/cd-release.yml@main
    with:
      enable-changelog: true
      version-format: "v%major.%minor.%patch"
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## ⚙️ Pré-requisitos & Permissões no GitHub

Para que o GitHub Actions possa criar Pull Requests e enviar tags/releases automaticamente, configure as permissões no repositório consumidor:

1. Acesse **Settings > Actions > General > Workflow permissions**.
2. Selecione **Read and write permissions**.
3. Marque a caixa **Allow GitHub Actions to create and approve pull requests**.
4. Clique em **Save**.

---

## 🏗️ Estratégias de Promoção de Branches

O workflow `cd-pull-request.yml` gerencia o ciclo de vida dos Pull Requests de acordo com a estratégia informada no input `strategy`:

| Estratégia | Fluxo de Promoção | Quando abre o PR de Release |
| :--- | :--- | :--- |
| **`trunk`** | `feature/**` → `main` | Imediatamente a cada push aprovado no CI |
| **`develop`** | `feature/**` → `develop` → `main` | Apenas quando há commits que alteram a versão |
| **`gitflow`** | `feature/**` → `develop` → `release-x.y.z` → `main` | Apenas quando há commits que alteram a versão |
| **`hotfix`** | `hotfix/**` → `main` | Sempre (override imediato para correção emergencial) |

> [!TIP]
> **Para que o GitFlow funcione em cascata de ponta a ponta:**  
> Certifique-se de que o workflow de CI (`Quality Assurance`) do repositório consumidor inclua a branch de release nos gatilhos de `push` (ex: `branches: ["develop", "feature/**", "hotfix/**", "release-*"]`).  
> Assim, ao mesclar a PR de `develop` para `release-x.y.z`, o CI será executado na branch de release e o workflow de Auto PR abrirá automaticamente a PR final da release para `main`.

### 🔥 Hotfix (O Override Controlado)
Branches prefixadas com `hotfix/*` são tratadas como exceção arquitetural controlada: **sempre abrem PR diretamente para a branch principal (`main`)**, ignorando a branch de desenvolvimento para garantir correção imediata de incidentes em produção.

---

## 📦 Catálogo de Reusable Workflows

### 1️⃣ CI — Quality Gate (`ci-quality-gate.yml`)

Detecta automaticamente a tecnologia do projeto, instala o runtime, roda os testes e avalia a cobertura de código.

```yaml
jobs:
  qa:
    uses: heliomarpm/reusable-workflows/.github/workflows/ci-quality-gate.yml@main
    with:
      stack: ''            # Opcional: 'node' ou 'php' (vazio = auto-detect)
      project-path: '.'     # Opcional: caminho do código (para monorepos/subpastas)
      coverage-min: 80     # Porcentagem mínima de cobertura exigida
      coverage-mode: block # 'block' (falha o job) | 'info' (alerta) | 'decrease' (bloqueia queda)
```

#### 🛡️ Modos de Avaliação do Quality Gate:
- **`block`**: Se a cobertura ficar abaixo de `coverage-min`, o job falha com erro vermelho. Como o Auto PR depende do sucesso do CI, o PR **não é aberto**.
- **`info`**: O CI sempre conclui com sucesso, mas anexa a etiqueta vermelha `coverage-failed` e a tabela detalhada de cobertura no PR para os revisores.
- **`decrease`**: Compara com a cobertura da branch de destino e impede regressões.

---

### 2️⃣ CD — Promoção Automática de Branches (`cd-pull-request.yml`)

Abre ou atualiza Pull Requests automaticamente, injetando o laudo de cobertura e métricas diretamente no corpo do PR.

```yaml
jobs:
  promote:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    uses: heliomarpm/reusable-workflows/.github/workflows/cd-pull-request.yml@main
    with:
      strategy: develop                    # trunk | develop | gitflow
      main-branch: 'main'                  # Nome da branch principal
      develop-branch: 'develop'            # Nome da branch de integração
      prefix-release-branch: 'release-'    # Prefixo usado no GitFlow (ex: release-1.2.0)
      pr-title: '🔀 PR ({{yyyy-MM-dd}}): {{HEAD_BRANCH}} → {{BASE_BRANCH}}'
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

> [!TIP]
> **Título Personalizado na Aba Actions (`run-name`):**  
> Para exibir exatamente as branches de origem e destino na lista de execuções do GitHub Actions:
> ```yaml
> run-name: "🔀 Auto PR: ${{ github.event.workflow_run.head_branch }} → ${{ github.event.workflow_run.head_branch == 'develop' && 'main' || 'develop' }}"
> ```

---

### 3️⃣ CD — Release Nativa & Zero-Dependency (`cd-release.yml`)

Engine ultra-rápida (< 2 segundos) para criação de **Git Tag**, **GitHub Release** e atualização opcional do `CHANGELOG.md` sem necessidade de Node.js, `npm install` ou ferramentas externas:

```yaml
jobs:
  release:
    uses: heliomarpm/reusable-workflows/.github/workflows/cd-release.yml@main
    with:
      enable-changelog: true                  # Opcional (default: true): atualiza o CHANGELOG.md
      version-format: "v%major.%minor.%patch" # Opcional: "v%major.%minor.%patch" ou "%YYYY-%mm-%dd"
      changelog-file: "CHANGELOG.md"          # Caminho do arquivo de changelog
      commit-changelog: true                  # Fazer commit e push do CHANGELOG.md
      prerelease-strategy: 'rc'               # 'rc' (default: v1.0.0-rc.1 em release-*) | 'same-tag' (v1.0.0 como pré-release)
      prerelease-suffix: 'rc'                 # Sufixo da pré-release para a estratégia 'rc' (default: 'rc')
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

> [!NOTE]
> **Estratégias de Pré-Release em Branches `release-*`:**  
> - **`rc` (Padrão / Recomendado)**: Na branch de release gera tags incrementais (`v1.0.0-rc.1`, `v1.0.0-rc.2`, etc.) marcadas como Pre-Release no GitHub. Ao fazer merge na `main`, publica a tag final limpa (`v1.0.0`) classificada como **Latest**.
> - **`same-tag`**: Na branch de release gera a tag de destino final (`v1.0.0`) como Pre-Release no GitHub. Ao fazer merge na `main`, essa mesma release é editada e promovida para **Latest** (`prerelease: false`).

---

### 4️⃣ CD — Semantic Release (`cd-semantic-release.yml`)

Para projetos que necessitam do ecossistema de plugins do `semantic-release` (análise avançada de commits, plugins npm, etc.):

```yaml
jobs:
  release:
    uses: heliomarpm/reusable-workflows/.github/workflows/cd-semantic-release.yml@main
    with:
      project-path: '.'                       # Subpasta onde está o código (opcional)
      prerelease-strategy: 'rc'               # 'rc' (default: v1.0.0-rc.1 em release-*) | 'same-tag' (v1.0.0)
      prerelease-suffix: 'rc'                 # Sufixo da pré-release (default: 'rc')
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### 5️⃣ CD — Publish Multi-Registry (`cd-publish.yml`)

Publicação automatizada e agnóstica de pacotes para **um ou múltiplos registries simultâneos**, com suporte a Node.js (`npm`), PHP (`Packagist`) ou comandos customizados:

```yaml
name: "4. Publish"

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      dry-run:
        type: boolean
        default: false

jobs:
  publish:
    uses: heliomarpm/reusable-workflows/.github/workflows/cd-publish.yml@main
    with:
      registries: 'npm, github' # Publica no npmjs.org e no GitHub Packages ao mesmo tempo!
      dry-run: ${{ inputs.dry-run || false }}
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🔒 Conventional Commits & Impacto nas Releases

O versionamento segue a especificação de [Conventional Commits](https://www.conventionalcommits.org/):

| Prefixo do Commit | Dispara Nova Release? | Impacto no SemVer | Exemplo |
| :--- | :---: | :---: | :--- |
| `feat:` | ✅ **Sim** | `minor` | `1.0.0` → `1.1.0` |
| `fix:` | ✅ **Sim** | `patch` | `1.0.0` → `1.0.1` |
| `perf:` | ✅ **Sim** | `patch` | `1.0.0` → `1.0.1` |
| `feat!:`, `refactor!:` ou `BREAKING CHANGE:` | ✅ **Sim** | `major` | `1.0.0` → `2.0.0` |
| `docs:` | ❌ Não | *(Nenhum)* | Apenas documentação |
| `chore:` | ❌ Não | *(Nenhum)* | Manutenção e dependências |
| `ci:` | ❌ Não | *(Nenhum)* | Ajustes de pipeline |
| `test:` | ❌ Não | *(Nenhum)* | Criação ou ajuste de testes |
| `refactor:` | ❌ Não | *(Nenhum)* | Refatoração interna sem quebra |

---

## 🔧 Composite Actions (Pipelines Customizados)

Se preferir montar seu próprio workflow passo a passo, utilize as ações atômicas da pasta `/actions`:

| Action | Descrição |
| :--- | :--- |
| `heliomarpm/reusable-workflows/actions/detect-stack@main` | Identifica a tecnologia do projeto (`node`, `php`, etc.). |
| `heliomarpm/reusable-workflows/actions/setup-runtime@main` | Configura versão e cache de dependências. |
| `heliomarpm/reusable-workflows/actions/run-tests@main` | Executa a suíte de testes unitários da stack. |
| `heliomarpm/reusable-workflows/actions/run-coverage@main` | Normaliza relatório de cobertura e valida metas mínimas. |
| `heliomarpm/reusable-workflows/actions/changelog@main` | Gera e comita exclusivamente o arquivo `CHANGELOG.md`. |
| `heliomarpm/reusable-workflows/actions/release@main` | Cria a Git Tag e publica a release oficial no GitHub. |
| `heliomarpm/reusable-workflows/actions/create-pr@main` | Cria ou atualiza Pull Requests via GitHub CLI. |
| `heliomarpm/reusable-workflows/actions/publish@main` | Publica artefatos em um ou múltiplos registries. |
| `heliomarpm/reusable-workflows/actions/semantic-release@main` | Wrapper otimizado para o runner do Semantic Release. |

### Exemplo de Uso Customizado:
```yaml
jobs:
  custom-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - id: stack
        uses: heliomarpm/reusable-workflows/actions/detect-stack@main
      - uses: heliomarpm/reusable-workflows/actions/setup-runtime@main
        with:
          stack: ${{ steps.stack.outputs.stack }}
      - uses: heliomarpm/reusable-workflows/actions/run-coverage@main
        with:
          stack: ${{ steps.stack.outputs.stack }}
          coverage-min: 85
          coverage-mode: block
```

---

## 🧱 Stacks Suportadas

| Stack | Detecção Automática | Ferramentas Suportadas | Cobertura |
| :--- | :--- | :--- | :--- |
| **Node.js** | `package.json` | Jest, Vitest, NPM, Yarn, PNPM | LCOV (`lcov.info`) |
| **PHP** | `composer.json` | PHPUnit, Pest, Composer | Clover XML (`clover.xml`) |
| **.NET / C#** | `*.csproj`, `*.sln` | *Em desenvolvimento* | OpenCover / Cobertura |
| **Python** | `pyproject.toml`, `requirements.txt` | *Em desenvolvimento* | Coverage.py |
| **Go** | `go.mod` | *Em desenvolvimento* | Go Cover |

---

## 📚 Documentação Técnica Interna & Agentes

Para detalhes técnicos avançados, funcionamento dos parsers em Bash, tratamento de escopo no GitHub Packages e referências de arquitetura (ADRs), consulte a documentação dedicada:
- 📖 [Arquitetura Interna & Guias de Mantenedores](.agents/ARCHITECTURE.md)
- 🤖 [Contexto para Agentes de IA](.agents/CONTEXT.md)
- 📐 [Architecture Decision Records (ADRs)](docs/adrs)

---

## 🤝 Contribuições & Suporte

- Quer contribuir com uma nova stack ou melhoria? Veja nosso [Guia de Contribuição](docs/CONTRIBUTING.md).
- Precisa de ajuda ou encontrou um problema? Consulte nosso [Suporte](docs/SUPPORT.md) ou abra uma [Issue](https://github.com/heliomarpm/reusable-workflows/issues).
- Leia o [Código de Conduta](docs/CODE_OF_CONDUCT.md).

Obrigado a todos que já contribuíram para o projeto!

<a href="https://github.com/heliomarpm/reusable-workflows/graphs/contributors" target="_blank">
<img src="https://contrib.nn.ci/api?repo=heliomarpm/reusable-workflows&no_bot=true" />
</a>

###### Criado com [contrib.nn](https://contrib.nn.ci/?repo=heliomarpm/reusable-workflows&no_bot=true).

Dito isso, existem várias maneiras de contribuir para este projeto, como:

⭐ Marcando o repositório com uma estrela (star) \
🐞 Relatando bugs \
💡 Sugerindo funcionalidades \
🧾 Melhorando a documentação \
📢 Compartilhando este projeto e recomendando-o aos seus amigos

## 💵 Apoie o Projeto

Se você gosta do projeto, considere fazer uma doação ao desenvolvedor via GitHub Sponsors, Ko-fi, PayPal ou Liberapay — a escolha é sua. 😉

<div class="badges">

  [![GitHub Sponsors][url-github-sponsors-badge]][url-github-sponsors]
  [![PayPal][url-paypal-badge]][url-paypal]
  [![Ko-fi][url-kofi-badge]][url-kofi]
  [![Liberapay][url-liberapay-badge]][url-liberapay]

</div>

## 📝 Licença

Distribuído sob a licença [MIT](LICENSE) © [Heliomar P. Marques](https://github.com/heliomarpm). <a href="#top">🔝</a>


----
<!-- Sponsor badges -->

[url-github-sponsors]: https://github.com/sponsors/heliomarpm
[url-github-sponsors-badge]: https://img.shields.io/badge/GitHub%20-Sponsor-1C1E26?style=for-the-badge&labelColor=1C1E26&color=db61a2
[url-kofi]: https://ko-fi.com/heliomarpm
[url-kofi-badge]: https://img.shields.io/badge/kofi-1C1E26?style=for-the-badge&labelColor=1C1E26&color=ff5f5f
[url-liberapay]: https://liberapay.com/heliomarpm
[url-liberapay-badge]: https://img.shields.io/badge/liberapay-1C1E26?style=for-the-badge&labelColor=1C1E26&color=f6c915
[url-paypal]: https://bit.ly/paypal-sponsor-heliomarpm
[url-paypal-badge]: https://img.shields.io/badge/donate%20on-paypal-1C1E26?style=for-the-badge&labelColor=1C1E26&color=0475fe

