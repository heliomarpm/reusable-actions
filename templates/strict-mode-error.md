## ❓ O que isso significa?

Este projeto exige que **todas as alterações promovidas para produção** sigam a especificação de **Commits Convencionais**.

Sem pelo menos um commit válido, o **semantic-release** não consegue determinar se a próxima versão deve ser:
- patch
- minor
- major

Por motivos de segurança, o processo de lançamento foi **intencionalmente bloqueado**.

---

## ✅ Como corrigir

Crie **pelo menos um commit** seguindo o formato de Commits Convencionais e envie-o para o repositório.

### Formato obrigatório

`<tipo>(<escopo>): <descrição curta>`

### Tipos aceitos

| Prefixo do Commit | Dispara Nova Release? | Impacto no SemVer | Exemplo |
| :--- | :---: | :---: | :--- |
| `feat:` | ✅ **Sim** | `minor` | `1.0.0` → `1.1.0` |
| `fix:` | ✅ **Sim** | `patch` | `1.0.0` → `1.0.1` |
| `perf:` | ✅ **Sim** | `patch` | `1.0.0` → `1.0.1` |
| `revert:` | ✅ **Sim** | `patch` | `1.0.0` → `1.0.1` |
| `BREAKING CHANGE:` ou `!` no prefixo | ✅ **Sim** | `major` | `1.0.0` → `2.0.0` |
| `docs:` | ❌ Não | *(Nenhum)* | Apenas documentação |
| `chore:` | ❌ Não | *(Nenhum)* | Manutenção e dependências |
| `ci:` | ❌ Não | *(Nenhum)* | Ajustes de pipeline |
| `test:` | ❌ Não | *(Nenhum)* | Criação ou ajuste de testes |
| `refactor:` | ❌ Não | *(Nenhum)* | Refatoração interna sem quebra |

---

## ✅ Exemplos válidos

<details><summary> detalhes </summary>

```bash
git commit -m "feat(auth): adicionar suporte a token de atualização"
git commit -m "fix(api): lidar com erro 500 ao salvar requisição"
git commit -m "fix(test): atualizar casos de teste para o novo endpoint"
git commit -m "chore: atualizar README.md"
git commit -m "test: adicionar novo caso de teste para o novo endpoint"
```

### 🚨 Alteração que quebra a compatibilidade (versão principal)

```bash
git commit -m "feat!: remover endpoint legado"
```

_ou_

```text
feat(core): nova API de ativação

BREAKING CHANGE: o endpoint de login foi removido
```
</details>

## 🧪 Dica para evitar erros futuros

Use auxiliares de commit para garantir o formato correto:

- `Commitizen`
- `Husky` + `commitlint`
- Git hook com `commit-msg`

📖 Consulte a [especificação de Commits Convencionais](https://www.conventionalcommits.org)

> ℹ️ Este bloco é intencional e faz parte da política de qualidade do projeto.