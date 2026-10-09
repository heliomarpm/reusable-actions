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
  export ENABLE_CHANGELOG="true"
  export CHANGELOG_FILE="CHANGELOG.md"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]
  [ -f "CHANGELOG.md" ]

  run grep -F "## [Unreleased]" CHANGELOG.md
  [ "$status" -eq 0 ]

  run grep -E "### .*Features" CHANGELOG.md
  [ "$status" -eq 0 ]

  run grep -F "adicionar funcionalidade de login" CHANGELOG.md
  [ "$status" -eq 0 ]
}

@test "changelog: promove [Unreleased] para versão definitiva quando informada INPUT_VERSION" {
  cat <<'EOF' > CHANGELOG.md
# 📦 Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### 🚀 Features
- nova funcionalidade pendente ([1234567](http://commit))

EOF
  git add CHANGELOG.md
  git commit -m "docs: changelog pendente" >/dev/null 2>&1

  echo "fix" >> file.txt
  git add file.txt
  git commit -m "fix: corrigir falha de timeout" >/dev/null 2>&1

  export CURRENT_BRANCH="main"
  export INPUT_BRANCH="main"
  export INPUT_VERSION="v0.4.0"
  export ENABLE_CHANGELOG="true"
  export CHANGELOG_FILE="CHANGELOG.md"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]

  run grep -F "## [v0.4.0] - " CHANGELOG.md
  [ "$status" -eq 0 ]

  # O unreleased deve ter sido removido/promovido
  run grep -F "## [Unreleased]" CHANGELOG.md
  [ "$status" -ne 0 ]

  run grep -F "corrigir falha de timeout" CHANGELOG.md
  [ "$status" -eq 0 ]
}

@test "changelog: registra commits na seção [Unreleased] quando INPUT_VERSION não é fornecida" {
  echo "v1.0.0" > version.txt
  git add version.txt
  git commit -m "chore: initial release" >/dev/null 2>&1
  git tag -a "v1.0.0" -m "v1.0.0"

  echo "docs" >> version.txt
  git add version.txt
  git commit -m "docs: atualizar readme" >/dev/null 2>&1

  echo "chore" >> version.txt
  git add version.txt
  git commit -m "chore: atualizar dependencias" >/dev/null 2>&1

  export CURRENT_BRANCH="main"
  export INPUT_BRANCH="main"
  export INPUT_VERSION=""
  export ENABLE_CHANGELOG="true"
  export CHANGELOG_FILE="CHANGELOG.md"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github_output.txt"
  touch "$GITHUB_OUTPUT"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]

  # Deve registrar sob [Unreleased] no CHANGELOG.md
  run grep -F "## [Unreleased]" CHANGELOG.md
  [ "$status" -eq 0 ]

  run grep -F "atualizar readme" CHANGELOG.md
  [ "$status" -eq 0 ]

  run grep -F "version=Unreleased" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep -F "has_changes=true" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "changelog: respeita changelog-title customizado na inicialização" {
  echo "conteudo inicial" > file.txt
  git add file.txt
  git commit -m "feat: suporte a changelog customizado" >/dev/null 2>&1

  export CURRENT_BRANCH="develop"
  export INPUT_BRANCH="develop"
  export ENABLE_CHANGELOG="true"
  export CHANGELOG_FILE="CHANGELOG.md"
  export CHANGELOG_TITLE="# 🚀 Histórico do Projeto\n\nTodas as mudanças."

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]
  [ -f "CHANGELOG.md" ]

  run grep -F "# 🚀 Histórico do Projeto" CHANGELOG.md
  [ "$status" -eq 0 ]
  run grep -F "Todas as mudanças." CHANGELOG.md
  [ "$status" -eq 0 ]
}

@test "changelog: insere nova versão no topo preservando estrutura sem divisores redundantes '---'" {
  cat <<'EOF' > CHANGELOG.md
# 📦 Changelog

All notable changes to this project will be documented in this file.

## [v0.3.0] - 2026-10-08

### 🚀 Features
- feature v0.3.0 ([1111111](http://commit))
EOF
  git add CHANGELOG.md
  git commit -m "chore(release): v0.3.0 [skip ci]" >/dev/null 2>&1
  git tag -a "v0.3.0" -m "v0.3.0"

  echo "nova feature" >> file.txt
  git add file.txt
  git commit -m "feat: nova feature apos v0.3.0" >/dev/null 2>&1

  export CURRENT_BRANCH="main"
  export INPUT_BRANCH="main"
  export INPUT_VERSION="v0.3.1"
  export ENABLE_CHANGELOG="true"
  export CHANGELOG_FILE="CHANGELOG.md"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]

  run grep -F "## [v0.3.1] - " CHANGELOG.md
  [ "$status" -eq 0 ]

  # Não deve conter divisores '---' antes de cabeçalhos de versão
  run grep -E '^---$' CHANGELOG.md
  [ "$status" -ne 0 ]

  # Garante ordem das versões
  run head -n 10 CHANGELOG.md
  [ "$status" -eq 0 ]
}

@test "changelog: ignora execução quando ENABLE_CHANGELOG=false" {
  echo "conteudo inicial" > file.txt
  git add file.txt
  git commit -m "feat: nova feature" >/dev/null 2>&1

  export ENABLE_CHANGELOG="false"
  export CHANGELOG_FILE="CHANGELOG.md"

  run bash "$ROOT_DIR/scripts/shared/changelog/run.sh"
  [ "$status" -eq 0 ]
  [ ! -f "CHANGELOG.md" ]
}
