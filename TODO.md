# 📌 Pendências e Roadmap do projeto `reusable-actions`

✅ **Fase 1 e 2 concluídas!** (Implementação das Composite Actions e reestruturação)
✅ **Fase 3 concluída!** (Estratégias `trunk`, `develop` e `gitflow` + engine de promoção)
✅ **Fase 4 em andamento!** (PHP adicionado. Faltam as próximas stacks)

## Próximos Passos Imediatos (Backlog)

### 1. Versionamento do Framework
- [ ] Aplicar release v1 no próprio repositório `reusable-actions`.
- [ ] O repo não tem um workflow nativo chamando seu próprio código (Dogfooding). Precisamos criar o `.github/workflows/release-self.yml`.

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
