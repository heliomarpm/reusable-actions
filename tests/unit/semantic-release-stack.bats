#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  export REUSABLE_PATH="$ROOT_DIR"
  export BASH_ENV="$ROOT_DIR/scripts/shared/shell-helpers.sh"
  
  TEST_TMPDIR="$(mktemp -d)"
  cd "$TEST_TMPDIR"
  
  export GITHUB_OUTPUT="$TEST_TMPDIR/output.txt"
  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_OUTPUT" "$GITHUB_STEP_SUMMARY"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Helper que emula a lógica do step '🔍 Resolve project stack'
resolve_stack_step() {
  source "$BASH_ENV"
  local SKIP_VERSION="${1:-false}"
  local INPUT_STACK="${2:-}"

  if [[ "$SKIP_VERSION" == "true" ]]; then
    echo "value=generic" >> "$GITHUB_OUTPUT"
    echo "source=skipped" >> "$GITHUB_OUTPUT"
    return 0
  fi

  if [[ -n "$INPUT_STACK" ]]; then
    local PLUGIN_CONFIG_JS="$REUSABLE_PATH/scripts/plugins/$INPUT_STACK/releaserc.js"
    local PLUGIN_CONFIG_JSON="$REUSABLE_PATH/scripts/plugins/$INPUT_STACK/releaserc.json"

    if [[ -f "$PLUGIN_CONFIG_JS" || -f "$PLUGIN_CONFIG_JSON" ]]; then
      echo "value=$INPUT_STACK" >> "$GITHUB_OUTPUT"
      echo "source=input" >> "$GITHUB_OUTPUT"
      return 0
    else
      fail "A stack '$INPUT_STACK' informada pelo consumidor não é suportada pelo Semantic Release."
    fi
  fi

  local SCRIPT="$REUSABLE_PATH/scripts/shared/detect-stack.sh"
  local DETECTED_STACK=""
  if [[ -f "$SCRIPT" ]]; then
    DETECTED_STACK=$(bash "$SCRIPT" 2>/dev/null || true)
  fi

  if [[ -z "$DETECTED_STACK" ]]; then
    echo "value=generic" >> "$GITHUB_OUTPUT"
    echo "source=not-detected" >> "$GITHUB_OUTPUT"
    return 0
  fi

  local PLUGIN_CONFIG_JS="$REUSABLE_PATH/scripts/plugins/$DETECTED_STACK/releaserc.js"
  local PLUGIN_CONFIG_JSON="$REUSABLE_PATH/scripts/plugins/$DETECTED_STACK/releaserc.json"

  if [[ -f "$PLUGIN_CONFIG_JS" || -f "$PLUGIN_CONFIG_JSON" ]]; then
    echo "value=$DETECTED_STACK" >> "$GITHUB_OUTPUT"
    echo "source=detected" >> "$GITHUB_OUTPUT"
    return 0
  else
    echo "value=generic" >> "$GITHUB_OUTPUT"
    echo "source=detected-unsupported" >> "$GITHUB_OUTPUT"
    return 0
  fi
}

@test "semantic-release/stack: ignora resolucao quando skip-version-file for true" {
  run resolve_stack_step "true" ""
  [ "$status" -eq 0 ]
  run grep -F "value=generic" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
  run grep -F "source=skipped" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "semantic-release/stack: aceita stack valida informada pelo consumidor" {
  run resolve_stack_step "false" "node"
  [ "$status" -eq 0 ]
  run grep -F "value=node" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
  run grep -F "source=input" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "semantic-release/stack: falha com erro bloqueante quando stack informada for invalida/nao suportada" {
  run resolve_stack_step "false" "ruby"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "não é suportada pelo Semantic Release" ]]
}

@test "semantic-release/stack: auto-detecao nao bloqueia quando nenhum sinal for encontrado e usa generic" {
  run resolve_stack_step "false" ""
  [ "$status" -eq 0 ]
  run grep -F "value=generic" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
  run grep -F "source=not-detected" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "semantic-release/stack: auto-detecao com stack sem plugin dedicado usa generic sem falhar" {
  touch pyproject.toml
  run resolve_stack_step "false" ""
  [ "$status" -eq 0 ]
  run grep -F "value=generic" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
  run grep -F "source=detected-unsupported" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}
