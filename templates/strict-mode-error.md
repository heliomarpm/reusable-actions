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

| Tipo      | Impacto no lançamento |
|:---|:---|
| feat!     | _major_ |
| refactor! | _major_ |
| feat      | _minor_ |
| fix       | _patch_ |
| revert    | _patch_ |
| perf      | _patch_ |
| chore     | -- |
| docs      | -- |
| test      | -- |

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