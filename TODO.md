# 📌 Pendências e Roadmap do projeto `reusable-actions`

✅ **Fase 1 e 2 concluídas!** (Implementação das Composite Actions e reestruturação)  
✅ **Fase 3 concluída!** (Estratégias `trunk`, `develop` e `gitflow` + engine de promoção com RC)  
✅ **Fase 4 concluída!** (Suporte consolidado a Node.js e PHP, templates modularizados e publish multi-registry)  

---

## 🎯 Meta Imediata: Fechamento da Versão Estável v1.0.0

### 1. Confiabilidade das Engines Internas & Testes
- [ ] **Testes para Scripts Bash com `bats-core`**: Cobrir `shell-helpers.sh`, bump SemVer de `release/run.sh`, parser de commits em `changelog/run.sh` e strict mode.

### 2. Validação E2E e Lançamento
- [ ] **Validação E2E no Consumidor**: Validar ciclo completo no repositório consumidor de testes (`reusable-actions-test-node`).
- [ ] **Lançamento Oficial v1.0.0**: Promover a versão estável oficial do repositório `reusable-actions`.

---

## 🚀 Expansão Multi-Stack (Roadmap Pós-v1.0.0)
> *Cada nova stack implementada deverá obrigatoriamente incluir a criação e execução de seus próprios testes automatizados.*

- [ ] **.NET**: Adicionar `install-deps.sh`, `test.sh`, `coverage.sh` (coverlet), `publish.sh` (NuGet) + testes da stack.
- [ ] **Python**: Adicionar `install-deps.sh`, `test.sh` (pytest), `coverage.sh` (coverage.py), `publish.sh` (twine) + testes da stack.
- [ ] **Go**: Adicionar `install-deps.sh`, `test.sh`, `coverage.sh` (`go test -cover`) + testes da stack.
- [ ] **Java & Flutter**: Suporte futuro.
