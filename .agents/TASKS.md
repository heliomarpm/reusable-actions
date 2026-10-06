# 📋 Project Tasks & Execution Backlog

> **Status Geral**: 🟢 Em Evolução  
> **Progresso**: 5/11 tarefas concluídas (45%)  
> **Última Atualização**: 2026-10-06  
> **Arquivo**: [TASKS.md](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/.agents/TASKS.md)

---

## 🎯 Meta da Iteração Atual
Expandir o suporte multi-stack (plugins de `.NET`, `Python` e `Go`) e implementar testes automatizados com `bats-core` para as engines em Bash, consolidando o ciclo GitFlow e pré-releases antes da versão `v1.0.0`.

---

## 🚀 1. Em Progresso (WIP - Limite: 2 tarefas)

- [/] **T-001: Implementar plugin para a stack .NET (C#)**
  - **Ref**: [scripts/plugins/dotnet/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/plugins/dotnet)
  - **Critérios de Aceite**:
    - [ ] Criar `install-deps.sh` (`dotnet restore`)
    - [ ] Criar `test.sh` (`dotnet test`)
    - [ ] Criar `coverage.sh` com normalização de cobertura (Coverlet / Cobertura XML)
    - [ ] Criar `publish.sh` para publicação de pacotes NuGet

---

## 📋 2. Backlog de Tarefas Prioritárias

### Fase 1: Expansão Multi-Stack
- [ ] **T-002: Implementar plugin para a stack Python**
  - **Ref**: [scripts/plugins/python/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/plugins/python)
  - **Critérios de Aceite**:
    - [ ] Criar `install-deps.sh` (`pip install` / `poetry` / `requirements.txt`)
    - [ ] Criar `test.sh` (suporte a `pytest`)
    - [ ] Criar `coverage.sh` (suporte a `coverage.py` com extração JSON)
    - [ ] Criar `publish.sh` (upload para PyPI / TestPyPI via `twine`)

- [ ] **T-003: Implementar plugin para a stack Go**
  - **Ref**: [scripts/plugins/go/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/plugins/go)
  - **Critérios de Aceite**:
    - [ ] Criar `install-deps.sh` (`go mod download`)
    - [ ] Criar `test.sh` e `coverage.sh` (`go test -coverprofile` e conversão)

### Fase 2: Confiabilidade & Testes das Engines Internas
- [ ] **T-004: Criar suíte de testes unitários para scripts Bash com `bats-core`**
  - **Ref**: [scripts/shared/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/shared)
  - **Critérios de Aceite**:
    - [ ] Configurar runner do Bats no CI do repositório
    - [ ] Testar helpers de string e templates em [shell-helpers.sh](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/shared/shell-helpers.sh)
    - [ ] Testar cálculo de SemVer e bumps em [release/run.sh](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/shared/release/run.sh)
    - [ ] Testar parser de commits e delimitadores ASCII em [changelog/run.sh](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/shared/changelog/run.sh)

### Fase 3: Validação de Consumo & Release Final
- [ ] **T-005: Validar fluxo E2E no repositório de teste consumidor (`reusable-actions-test-node`)**
  - **Ref**: [README.md](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/README.md)
  - **Critérios de Aceite**:
    - [ ] Validar cadeia GitFlow completa: `feature` → `develop` → `release-*` (com RC) → `main`
    - [ ] Validar override de `hotfix/*` direto para `main`
    - [ ] Documentar repositório de demonstração oficial no README principal

- [ ] **T-006: Lançamento oficial da versão v1.0.0**
  - **Ref**: [cd-release.yml](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/.github/workflows/cd-release.yml)
  - **Critérios de Aceite**:
    - [ ] Promover tags e formalizar a release principal v1.0.0

---

## 💡 3. Débitos Técnicos & Melhorias Futuras

- [ ] **T-007: Plugins futuros para Java e Flutter**
  - **Ref**: [TODO.md](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/TODO.md)
  - Mapear suporte a Gradle/Maven (Java) e Flutter CLI.

---

## ✅ 4. Concluído Recentemente

- [x] **T-C01: Separação de responsabilidades de Changelog e Release** *(Concluído em 2026-10-06)*
  - **Ref**: [actions/changelog/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/actions/changelog), [actions/release/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/actions/release)
  - Desacoplamento da geração de `CHANGELOG.md` e da criação de Git Tags e GitHub Releases.

- [x] **T-C02: Suporte a pré-releases (RC) e estratégia GitFlow completa** *(Concluído em 2026-10-06)*
  - **Ref**: [changelog/run.sh](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/shared/changelog/run.sh), [release/run.sh](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/shared/release/run.sh)
  - Suporte a tags `v1.0.0-rc.1` em branches `release-*` e promoção para versão estável na `main`.

- [x] **T-C03: Modularização dinâmica de templates Markdown** *(Concluído em 2026-10-06)*
  - **Ref**: [templates/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/templates/), [shell-helpers.sh](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/shared/shell-helpers.sh)
  - Extração de 17 templates com renderização dinâmica de variáveis e summaries via `append_template_to_summary`.

- [x] **T-C04: Motor de Publicação Multi-Registry** *(Concluído em 2026-10-05)*
  - **Ref**: [actions/publish/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/actions/publish), [cd-publish.yml](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/.github/workflows/cd-publish.yml)
  - Suporte a publicação simultânea em múltiplos registries com auto-scoping para GitHub Packages.

- [x] **T-C05: Modo `decrease` no Quality Gate** *(Concluído em 2026-10-03)*
  - **Ref**: [actions/run-coverage/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/actions/run-coverage)
  - Comparação da cobertura atual com a branch base para impedir regressões.
