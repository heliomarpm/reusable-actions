#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  export REUSABLE_PATH="$ROOT_DIR"
  export BASH_ENV="$ROOT_DIR/scripts/shared/shell-helpers.sh"
  
  TEST_TMPDIR="$(mktemp -d)"
  cd "$TEST_TMPDIR"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "detect-stack: identifica projeto node via package.json" {
  touch package.json
  run bash "$ROOT_DIR/scripts/shared/detect-stack.sh"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "node" ]
}

@test "detect-stack: identifica projeto php via composer.json" {
  touch composer.json
  run bash "$ROOT_DIR/scripts/shared/detect-stack.sh"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "php" ]
}

@test "detect-stack: identifica projeto dotnet via .csproj" {
  touch App.csproj
  run bash "$ROOT_DIR/scripts/shared/detect-stack.sh"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "dotnet" ]
}

@test "detect-stack: identifica projeto python via pyproject.toml" {
  touch pyproject.toml
  run bash "$ROOT_DIR/scripts/shared/detect-stack.sh"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "python" ]
}

@test "detect-stack: identifica projeto go via go.mod" {
  touch go.mod
  run bash "$ROOT_DIR/scripts/shared/detect-stack.sh"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "go" ]
}

@test "detect-stack: auto-detecta stack em subpasta única (ex: app/package.json)" {
  mkdir app
  touch app/package.json
  run bash "$ROOT_DIR/scripts/shared/detect-stack.sh"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "node" ]
}

@test "detect-stack: falha com exit code 1 e gera step summary quando nenhum manifesto for encontrado" {
  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  run bash "$ROOT_DIR/scripts/shared/detect-stack.sh"
  [ "$status" -eq 1 ]
  
  run grep -F "Falha na Detecção de Stack" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}
