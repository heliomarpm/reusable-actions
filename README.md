# Agnostic CI/CD

A stack-agnostic CI/CD framework for GitHub Actions.

> ⚠️ This project is production-ready and used as CI/CD foundation.
> Versioning and releases are fully automated.

![CI](https://github.com/heliomarpm/ci-cd-reusable/actions/workflows/ci.yml/badge.svg)


## ✨ Features
- 🔍 Automatic stack detection (Node, PHP, .NET, Python, Go)
- 🧪 Automated unit test execution
- 🔀 Automatic Pull Request creation
- 🚀 Release automation (coming next)
- 🧾 Changelog generation (coming next)

## 📦 Supported Stacks
- Node.js
- PHP
- .NET
- Python
- Go

## 🚀 Getting Started

### Option 1: Template repository
Click **Use this template** and start coding.

### Option 2: Reuse workflows
```yaml
uses: your-org/agnostic-ci-cd/.github/workflows/ci.yml@v1
```

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

## 📦 Release & Versioning

This project follows **Conventional Commits**.

### Supported types
- feat → minor
- fix → patch
- perf → patch
- BREAKING CHANGE → major

### Release trigger
- Merge to `main`

### Outputs
- Git tag
- GitHub Release
- Updated CHANGELOG.md

---

## Roadmap

- [x] Stack detection
- [x] PR automation
- [x] Test execution
- [x] Release automation
- [x] Semantic versioning
- [x] Changelog automation

