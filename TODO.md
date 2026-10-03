# 📌 Pendências e Roadmap do projeto `reusable-actions`

✅ **Fase 1 e 2 concluídas!** (Implementação das Composite Actions e reestruturação)
✅ **Fase 3 concluída!** (Estratégias `trunk`, `develop` e `gitflow` + engine de promoção)
✅ **Fase 4 em andamento!** (PHP adicionado. Faltam as próximas stacks)

## Próximos Passos Imediatos (Backlog)

### 1. Versionamento do Framework
- [x] **Action de Changelog Nativa (`actions/changelog`)**: Implementada com zero dependências externas, ciclo de vida `[Unreleased]` atômico, promoção para versão na main (por data `YYYY-MM-DD` ou SemVer) e suporte a Git Tag / GitHub Release.
- [x] **Workflow de Dogfooding (`.github/workflows/changelog.yml`)**: Implementado para executar `actions/changelog` no próprio repositório a cada merge ou commit na main/develop.
- [ ] Aplicar release v1 no próprio repositório `reusable-actions`.

### 2. Multi-Stack (Próximas Stacks)
- [ ] **.NET**: Adicionar `scripts/plugins/dotnet/install-deps.sh`, `test.sh`, `coverage.sh` (cobertura via coverlet) e `releaserc.json`.
- [ ] **Python**: Adicionar plugins `python` (suporte a pytest, coverage.py).
- [ ] **Go**: Adicionar plugins `go` (suporte a `go test -cover`).
- [ ] **Java** (Futuro)
- [ ] **Flutter** (Futuro)

### 3. Melhorias nas Actions e Scripts
- [ ] **Estratégia `decrease-only`**: Na action de cobertura, criar uma inteligência para comparar o artefato de cobertura atual com o artefato da branch alvo (base), falhando apenas se o percentual diminuir.
- [ ] **Testes para Scripts Bash**: Usar `bats-core` para testar as unidades lógicas em `shell-helpers.sh`, `detect-stack.sh`, etc.
- [ ] **Publishers (cd-publish)**: Melhorar a abstração para publicação npm/packagist etc.

### 4. Exemplos Reais
- [ ] Criar um repositório consumidor de exemplo apenas para simular o workflow e deixar exposto no README.
