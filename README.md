# Agnostic CI/CD

![CI](https://github.com/heliomarpm/reusable-actions/actions/workflows/ci.yml/badge.svg)

A **technology-agnostic, reusable CI/CD framework** for GitHub Actions.

This project provides a complete CI/CD foundation that can be reused across multiple repositories, regardless of the programming language or stack.

It handles:
- Stack detection
- Unit test execution
- Pull Request automation
- Semantic releases
- Automatic changelog generation

All with **zero vendor lock-in** and **minimal configuration**.

---

## ✨ Features

- 🔍 **Automatic stack detection**
  - Node.js
  - PHP (Composer or pure PHP)
  - .NET
  - Python (pip, Poetry, Pipenv, UV)
  - Go

- 🧪 **Unit test execution** per stack
- 🔀 **Automatic Pull Request creation**
  - `feature/* → develop`
  - `develop → main`
- 🚀 **Automatic release on merge to `main`**
- 🧾 **Semantic Versioning & CHANGELOG.md**
- ♻️ **Reusable workflows** (`uses:`)
- ⚙️ **Override-friendly via environment variables**

---

## 🧠 Design Principles

- Stack-agnostic by default
- Convention over configuration
- Fail fast, fail clearly
- No hidden magic
- Easy to extend, easy to debug

---

## 📦 Supported Stacks

| Stack   | Detection Strategy |
|--------|--------------------|
| Node.js | `package.json`, `yarn.lock`, `pnpm-lock.yaml` |
| PHP | `composer.json`, `index.php`, `default.php` |
| .NET | `*.csproj`, `*.sln` |
| Python | `requirements.txt`, `pyproject.toml`, `Pipfile`, `poetry.lock`, `uv.lock`, `setup.py` |
| Go | `go.mod` |

---

## 🚀 Getting Started

### Option 1 — Use as a Template Repository
Click **"Use this template"** on GitHub and start coding.

### Option 2 — Reuse in an existing project

Create a workflow in your project:

```yaml
name: CI

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop]

jobs:
  ci:
    uses: heliomarpm/reusable-actions/.github/workflows/ci.yml@v1
```    

---

## ⚙️ Configuration

Override detected stack:

```yaml
env:
  STACK: Node
```  

Skip tests:

```yaml
env:
  SKIP_TESTS: true
```

---

## 🔀 Pull Request Automation

This project automatically creates and updates Pull Requests:

| Source Branch | Target Branch |
| ------------- | ------------- |
| `feature/*`   | `develop`     |
| `develop`     | `main`        |


PRs are idempotent and never duplicated.

---

## 🚀 Release & Versioning

Releases are fully automated and triggered when a Pull Request is merged into `main`.

**Versioning Rules (Conventional Commits)**

| Commit Type       | Release Impact |
| ----------------- | -------------- |
| `feat:`           | minor          |
| `fix:`            | patch          |
| `perf:`           | patch          |
| `BREAKING CHANGE` | major          |


**What happens on release**

- New Git tag (`vX.Y.Z`)
- GitHub Release created
- `CHANGELOG.md` updated and committed

---

## 🧾 CHANGELOG

The `CHANGELOG.md` file is generated automatically from commit history.

Do not edit it manually.

---

## 🧪 Unit Tests

Each stack has its own test strategy:

| Stack  | Command                      |
| ------ | ---------------------------- |
| Node   | `npm test`                   |
| PHP    | `phpunit`                    |
| .NET   | `dotnet test`                |
| Python | `pytest` (pip / Poetry / UV) |
| Go     | `go test ./...`              |

---

## 🛣 Roadmap

- [x] Stack detection
- [x] Unit test execution
- [x] PR automation
- [x] Semantic releases
- [x] Changelog automation
- [ ] Deployment hooks
- [ ] Matrix builds
- [ ] Config via .ci-cd.yml

--- 

## 🤝 Contributing

Contributions are welcome!

Please follow:

- Conventional Commits
- Clear, minimal changes
- Stack-agnostic mindset

See [CONTRIBUTING](.github/CONTRIBUTING.md) for details.

---

```
scripts/
│
├── core/
│   ├── engine.sh
│   ├── plugin-loader.sh
│   ├── contracts.sh
│   ├── lifecycle.sh
│   ├── logger.sh
│   └── utils.sh
│
├── plugins/
│   ├── node/
│   │    ├── plugin.sh
│   │    ├── release.sh
│   │    ├── test.sh
│   │    ├── coverage.sh
│   │    └── publish.sh
│   │
│   ├── php/
│   ├── python/
│   ├── dotnet/
│   └── go/
│
└── detect-stack.sh
```