# 🚫 RELEASE BLOCKED — STRICT MODE ACTIVE

No valid **Conventional Commits** were found since the last release.

---

## ❓ What does this mean?

This project requires that **all changes promoted to production** follow the **Conventional Commits** specification.

Without at least one valid commit, **semantic-release** cannot determine whether the next version should be a:
- patch
- minor
- major

For safety reasons, the release process has been **intentionally blocked**.

---

## ✅ How to fix

Create **at least one commit** following the Conventional Commits format and push it to the repository.

### Required format

`<type>(<scope>): <short description>`

### Accepted Types

| Type   | Release impact |
|--------|----------------|
| feat   | minor          |
| fix    | patch          |
| revert | patch          |
| chore  | ❌ none        |
| docs   | ❌ none        |
| test   | ❌ none        |

---

## ✅ Valid examples

<details><summary> details </summary>
```bash
git commit -m "feat(auth): add refresh token support"
git commit -m "fix(api): handle 500 error when saving request"
git commit -m "fix(test): update test cases for new endpoint"
git commit -m "chore: update README.md"
git commit -m "test: add new test case for new endpoint"
```

### 🚨 Breaking change (major release)

```bash
git commit -m "feat!: remove legacy endpoint"
```
_or_

```text
feat(core): nova API de autenticação

BREAKING CHANGE: o endpoint /login foi removido
```
</details>

## 🧪 Tip to avoid future errors

Use commit helpers to enforce the correct format:

- Commitizen
- Husky + commitlint
- Git hook with commit-msg

📘 Documentation:

https://www.conventionalcommits.org


ℹ️ This block is intentional and is part of the project's quality policy.


