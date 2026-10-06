# 📋 Project Tasks & Execution Backlog

> **Status Geral**: 🟢 Em Evolução  
> **Progresso**: 6/11 tarefas concluídas (55%)  
> **Última Atualização**: 2026-10-06  
> **Arquivo**: [TASKS.md](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/.agents/TASKS.md)

---

## 🎯 Meta da Iteração Atual (Rumo à v1.0.0)
Consolidar a estabilidade do Core da biblioteca através de testes automatizados com `bats-core` e validação E2E do ciclo GitFlow/Releases no repositório de testes, finalizando o lançamento oficial da **v1.0.0** antes de iniciar a expansão para novas stacks.

---

## 🚀 1. Em Progresso (WIP - Limite: 2 tarefas)

- [/] **T-002: Validar fluxo E2E no repositório de teste consumidor (`reusable-actions-test-node`)**
  - **Ref**: [README.md](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/README.md)
  - **Critérios de Aceite**:
    - [ ] Validar cadeia GitFlow completa: `feature` → `develop` → `release-*` (com RC) → `main`
    - [ ] Validar override de `hotfix/*` direto para `main`
    - [ ] Validar commits convencionais sem release (`ci:`, `chore:`, `docs:`) concluindo com sucesso verde
    - [ ] Documentar repositório de demonstração oficial no README principal

---

## 📋 2. Backlog de Tarefas Prioritárias

### Fase 1: Confiabilidade do Core & Validação E2E (Fechamento da v1.0.0)
- [ ] **T-003: Lançamento oficial da versão estável v1.0.0**
  - **Ref**: [cd-release.yml](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/.github/workflows/cd-release.yml)
  - **Critérios de Aceite**:
    - [ ] Fechar marcos e notas de lançamento estáveis
    - [ ] Promover tags e formalizar a release principal v1.0.0 do projeto

---

### Fase 2: Expansão Multi-Stack (Pós-v1.0.0)
> ⚠️ **Regra Mandatória**: Cada nova stack implementada deve obrigatoriamente incluir a criação e execução de seus próprios testes unitários e de integração.

- [ ] **T-004: Implementar plugin para a stack .NET (C#) com testes dedicados**
  - **Ref**: [scripts/plugins/dotnet/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/plugins/dotnet)
  - **Critérios de Aceite**:
    - [ ] Criar `install-deps.sh` (`dotnet restore`)
    - [ ] Criar `test.sh` (`dotnet test`)
    - [ ] Criar `coverage.sh` com normalização de cobertura (Coverlet / Cobertura XML)
    - [ ] Criar `publish.sh` para pacotes NuGet
    - [ ] **Testes da Stack**: Criar projeto de teste de exemplo para validar a suíte do plugin

- [ ] **T-005: Implementar plugin para a stack Python com testes dedicados**
  - **Ref**: [scripts/plugins/python/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/plugins/python)
  - **Critérios de Aceite**:
    - [ ] Criar `install-deps.sh` (`pip install` / `poetry` / `requirements.txt`)
    - [ ] Criar `test.sh` (suporte a `pytest`)
    - [ ] Criar `coverage.sh` (suporte a `coverage.py` com extração JSON)
    - [ ] Criar `publish.sh` (upload para PyPI / TestPyPI via `twine`)
    - [ ] **Testes da Stack**: Criar suíte de testes de integração para o plugin Python

- [ ] **T-006: Implementar plugin para a stack Go com testes dedicados**
  - **Ref**: [scripts/plugins/go/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/scripts/plugins/go)
  - **Critérios de Aceite**:
    - [ ] Criar `install-deps.sh` (`go mod download`)
    - [ ] Criar `test.sh` e `coverage.sh` (`go test -coverprofile` e conversão de cobertura)
    - [ ] **Testes da Stack**: Criar projeto de teste de exemplo para validar o plugin Go

---

## 💡 3. Débitos Técnicos & Roadmap Futuro

- [ ] **T-007: Plugins futuros para Java e Flutter com testes dedicados**
  - **Ref**: [TODO.md](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/TODO.md)
  - Suporte a Gradle/Maven (Java) e Flutter CLI.

---

## ✅ 4. Concluído Recentemente

- [x] **T-001: Suíte de testes automatizados para scripts Bash com `bats-core`** *(Concluído em 2026-10-06)*
  - **Ref**: [tests/](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/tests), [.github/workflows/ci.yml](file:///d:/WORKS/DEV/GitHubActions/reusable-actions/.github/workflows/ci.yml)
  - 28 testes cobrindo `shell-helpers`, `changelog`, `release`, `semantic-release` (strict mode) e `detect-stack`.

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
