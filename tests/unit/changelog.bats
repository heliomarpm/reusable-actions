#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  export REUSABLE_PATH="$ROOT_DIR"
  export BASH_ENV="$ROOT_DIR/scripts/shared/shell-helpers.sh"
  
  TEST_TMPDIR="$(mktemp -d)"
  cd "$TEST_TMPDIR"
  
  git init -b main >/dev/null 2>&1
  git config user.name "Tester"
  git config user.email "tester@example.com"

  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_STEP_SUMMARY"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "changelog: gera seção [Unreleased] em branch develop" {
  echo "conteudo inicial" > file.txt
  git add file.txt
  git commit -m "feat: adicionar funcionalidade de login" >/dev/null 2>&1

  export CURRENT_BRANCH="develop"
  export INPUT_BRANCH="develop"
  export COMMIT_CHANGELOG="false"
  export CHANGELOG_FILE="CHANGELOG.md"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]
  [ -f "CHANGELOG.md" ]

  run grep -F "## [Unreleased]" CHANGELOG.md
  [ "$status" -eq 0 ]

  run grep -F "### 🚀 Features" CHANGELOG.md
  [ "$status" -eq 0 ]

  run grep -F "adicionar funcionalidade de login" CHANGELOG.md
  [ "$status" -eq 0 ]
}

@test "changelog: promove [Unreleased] para versão definitiva na branch main" {
  # 1. Cria changelog com unreleased
  cat <<'EOF' > CHANGELOG.md
# 📦 Changelog

## [Unreleased]

### 🚀 Features
- nova funcionalidade pendente ([1234567](http://commit))

EOF
  git add CHANGELOG.md
  git commit -m "docs: changelog pendente" >/dev/null 2>&1

  # Adiciona novo commit fix
  echo "fix" >> file.txt
  git add file.txt
  git commit -m "fix: corrigir falha de timeout" >/dev/null 2>&1

  export CURRENT_BRANCH="main"
  export INPUT_BRANCH="main"
  export COMMIT_CHANGELOG="false"
  export CHANGELOG_FILE="CHANGELOG.md"
  export VERSION_FORMAT="v%major.%minor.%patch"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]

  # Deve ter criado uma versão definitiva com v0.0.1 ou data
  run grep -E "## \[v[0-9]+\.[0-9]+\.[0-9]+\]" CHANGELOG.md
  [ "$status" -eq 0 ]

  # O unreleased deve ter sido removido/promovido
  run grep -F "## [Unreleased]" CHANGELOG.md
  [ "$status" -ne 0 ]

  # O conteúdo pendente e o novo fix devem estar presentes
  run grep -F "corrigir falha de timeout" CHANGELOG.md
  [ "$status" -eq 0 ]
}

@test "changelog: gera tag de pré-release (RC) em branch release-*" {
  echo "codigo" > file.txt
  git add file.txt
  git commit -m "feat: preparar lancamento" >/dev/null 2>&1

  export CURRENT_BRANCH="release-1.2.0"
  export INPUT_BRANCH="release-1.2.0"
  export PRERELEASE_STRATEGY="rc"
  export PRERELEASE_SUFFIX="rc"
  export COMMIT_CHANGELOG="false"
  export CHANGELOG_FILE="CHANGELOG.md"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]

  run grep -F "## [v1.2.0-rc.1]" CHANGELOG.md
  [ "$status" -eq 0 ]
}
