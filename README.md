# 🚀 Reusable Actions — CI, Auto PR & Semantic Release

Conjunto de GitHub Reusable Workflows para padronizar CI, cobertura, promoção de código e releases automatizados, com suporte a múltiplas stacks.

> **Observação**: Este workflow utiliza o [GitHub Actions Reusable Workflow](https://docs.github.com/en/actions/using-reusable-workflows) para reutilizar o processo de CI/CD.

## 🧠 Filosofia

> "Automação sem disciplina cria caos. \
> Disciplina sem automação não escala.

Este projeto existe para equilibrar os dois.

## 🎯 Objetivos

- Reduzir boilerplate em pipelines
- Padronizar versionamento com `semantic-release`
- Garantir qualidade mínima com **STRICT MODE**
- Permitir evolução por stack sem acoplamento
- Entregar informações claras nos sumários do Pipeline

---

## 📦 Workflows disponíveis

> Todas os workflows reutilizáveis podem ser usadas em qualquer repositório, eles estão disponíveis no repositório [heliomarpm/reusable-actions](https://github.com/heliomarpm/reusable-actions).


### 1️⃣ CI — Testes e Cobertura

Este workflow executa os testes e gera a cobertura de testes.

```yaml
name: CI
jobs:
  ci:
    uses: heliomarpm/reusable-actions/.github/workflows/ci.yml@v1
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs principais**

| Input                      | Descrição                           |
| -------------------------- | ----------------------------------- |
| `project_path`             | Caminho do projeto                  |
| `stack`                    | node / php / dotnet / python / go   |
| `skip_tests`               | Ignora execução de testes           |
| `test_continue_on_failure` | Não falha pipeline em erro de teste |

---

### 2️⃣ Auto PR — Promoção automática de branches

Este workflow cria um Pull Request para a promoção de um branch para outra.

Padrão de promoção: `direct`. 

- `feature/*` → `develop`
- `develop` → `main`

Se atribuir `release-branch` ao input `promotion_strategy`, o workflow criará um Pull Request para a promoção de um branch para `release-x.y.z`.

- `develop` → `release-x.y.z`
- `release-x.y.z` → `main`


```yaml
name: Auto PR
jobs:
  auto-pr:
    uses: heliomarpm/reusable-actions/.github/workflows/auto-pr.yml@v1
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```

**Inputs principais**

| Input                         | Descrição                           |
| --------------------------    | ----------------------------------- |
| `min-coverage`                | Percentual mínimo de cobertura (padrão: 80)      |
| `coverage-mode`               | info / block / decrease-only (padrão: info)        |
| `promotion_strategy`          | direct / release-branch (padrão: direct)           |
| `semantic_release_config`     | Caminho do arquivo de config do semantic-release (utilizado se promotion_strategy = release-branch)          |
| `strict_conventional_commits` | Ativa o modo strict (utilizado se promotion_strategy = release-branch)           |

**Estratécias de Cobertura (coverage_mode)**

| Estratégia | Comportamento |
| --------- | ------------- |
| `info`    | Apenas informativo          |
| `block`   | Bloqueia PR se abaixo do percentual mínimo de cobertura  |
| `decrease-only` | Bloqueia PR se abaixo da cobertura anterior (em construção) |

**Estratégias de promoção (promotion_strategy)**

| Estratégia       | Comportamento            |
| ---------------- | ------------------------ |
| `direct`         | feature → develop → main |
| `release-branch` | develop → release-x.y.z  |

--- 
### 3️⃣ Release — Semantic Release

Este workflow executa o `semantic-release` para gerar novas versões e criar/releases no GitHub.

```yaml
name: Release
jobs:
  release:
    uses: heliomarpm/reusable-actions/.github/workflows/release.yml@v1
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### 🔒 STRICT MODE — Commits Convencionais

Opção disponível para os fluxo `auto-pr` e `release`, e quando ativado, bloqueia o release se não houver commits válidos desde o último lançamento.

```yaml
with:
  strict_conventional_commits: true
```

**O que acontece?**

- ❌ Release bloqueado
- 📌 Annotation visível no Job
- 📄 Instruções detalhadas no Summary

Isso evita:

- Releases silenciosos
- Versionamento incorreto
- Ambiguidade no histórico

---

## 🧱 Stacks suportadas

- ✅ Node.js
- 🚧 PHP
- 🚧 .NET
- 🚧 Python
- 🚧 Go

Cada stack possui seus próprios scripts em:

`scripts/plugins/<stack>`

--- 

## 📈 Versionamento Semântico

Este modelo usa o [semantic-release](https://semantic-release.gitbook.io/) para gerenciamento automático de versões e publicação de pacotes. Os números de versão são determinados automaticamente com base nas mensagens de commit:

`<tipo>(<scope>): <mensagem curta>`

**Examplos**

| Mensagem de Commit | Tipo de Release | Exemplo de Versão |
| :--------------------------- | :----------- | --------------: |
| `revert(scope): message` | Patch | 1.0.1 |
| `fix(scope): message` | Patch | 1.0.1 |
| `feat(scope): message` | Minor | 1.1.0 |
| `BREAKING CHANGE: message` | Major | 2.0.0 |

### 📝 Formato da Mensagem de Commit

```bash
<tipo>(<escopo>): <resumo curto>
│       │             │
│       │             └─⫸ Resumo no presente do indicativo. Sem maiúsculas. Sem ponto final.
│       │
│       └─⫸ Escopo do Commit: core|docs|config|cli|etc.
│
└─⫸ Tipo de Commit: fix|feat|build|chore|ci|docs|style|refactor|perf|test
```

Quando um commit é enviado para a branch `main`:

1. O semantic-release analisa as mensagens de commit
2. Determina o próximo número de versão
3. Gera o changelog
4. Cria uma tag git
5. Publica a versão no GitHub

> **Nota**: Para disparar uma versão, os commits devem seguir a especificação [Conventional Commits](https://www.conventionalcommits.org/).

---

## 📌 Roadmap

- [x] Agnostico de stacks
- [x] Execução de testes unitários
- [x] Automação de PR com estratégias de promoção
- [x] Release semânticos com Strict Mode
- [x] Automação de changelog
- [ ] Publicação por stack


---

## 🤝 Contribuições

Pull Requests são bem-vindos. \
Sugestões de stack, melhorias de DX e exemplos reais são prioridade.

Por favor, leia:

- [Código de Conduta](docs/CODE_OF_CONDUCT.md)
- [Guia de Contribuição](docs/CONTRIBUTING.md)

Agradecemos a todos que já contribuíram para o projeto!

<a href="https://github.com/heliomarpm/reusable-actions/graphs/contributors" target="_blank">

<!-- <img src="https://contrib.rocks/image?repo=heliomarpm/tsapp-template" /> -->
<img src="https://contrib.nn.ci/api?repo=heliomarpm/reusable-actions&no_bot=true" />
</a>

<!-- ###### Feito com [contrib.rocks](https://contrib.rocks). -->
###### Feito com [contrib.nn](https://contrib.nn.ci).

### ❤️ Apoie este projeto

Se este projeto lhe foi útil de alguma forma, existem várias maneiras de contribuir. \
Ajude-nos a manter e melhorar este modelo:

⭐ Adicione o repositório aos seus favoritos \
🐞 Reporte erros \
💡 Sugira funcionalidades \
🧾 Melhore a documentação \
📢 Compartilhe com outras pessoas

💵 Apoie através do GitHub Sponsors, Ko-fi, PayPal ou Liberapay, você decide. 😉

<div class="badges">
[![PayPal][url-paypal-badge]][url-paypal]
[![Ko-fi][url-kofi-badge]][url-kofi]
[![Liberapay][url-liberapay-badge]][url-liberapay]
[![GitHub Sponsors][url-github-sponsors-badge]][url-github-sponsors]
</div>

## 📝 Licença

[MIT © Heliomar P. Marques](LICENSE) <a href="#top">🔝</a>

----
<!-- Sponsor badges -->
[url-paypal-badge]: https://img.shields.io/badge/donate%20on-paypal-1C1E26?style=for-the-badge&labelColor=1C1E26&color=0475fe
[url-paypal]: https://bit.ly/paypal-sponsor-heliomarpm

[url-kofi-badge]: https://img.shields.io/badge/kofi-1C1E26?style=for-the-badge&labelColor=1C1E26&color=ff5f5f
[url-kofi]: https://ko-fi.com/heliomarpm

[url-liberapay-badge]: https://img.shields.io/badge/liberapay-1C1E26?style=for-the-badge&labelColor=1C1E26&color=f6c915
[url-liberapay]: https://liberapay.com/heliomarpm

[url-github-sponsors-badge]: https://img.shields.io/badge/GitHub%20-Sponsor-1C1E26?style=for-the-badge&labelColor=1C1E26&color=db61a2
[url-github-sponsors]: https://github.com/sponsors/heliomarpm
