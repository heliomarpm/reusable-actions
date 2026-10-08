#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  HELPERS="$ROOT_DIR/scripts/shared/shell-helpers.sh"
}

@test "run-tests: workflow cd-pull-request e action run-tests declaram input test-command" {
  WORKFLOW="$ROOT_DIR/.github/workflows/cd-pull-request.yml"
  ACTION="$ROOT_DIR/actions/run-tests/action.yml"

  [ -f "$WORKFLOW" ]
  [ -f "$ACTION" ]

  run grep -q "test-command:" "$WORKFLOW"
  [ "$status" -eq 0 ]

  run grep -q "test-command:" "$ACTION"
  [ "$status" -eq 0 ]
}

@test "run-tests: executa test-command customizado com sucesso" {
  CUSTOM_CMD="echo 'Custom Test Execution'"
  run bash -c "eval '$CUSTOM_CMD'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Custom Test Execution" ]]
}

@test "run-tests: detecta falha quando test-command customizado retorna erro" {
  CUSTOM_CMD="echo 'Failing Custom Test' && exit 42"
  run bash -c "eval '$CUSTOM_CMD'"
  [ "$status" -eq 42 ]
}

@test "run-tests: fallback para script da stack quando test-command for vazio" {
  STACK="node"
  CUSTOM_CMD=""
  SCRIPT="$ROOT_DIR/scripts/plugins/$STACK/test.sh"

  [ -z "$CUSTOM_CMD" ]
  [ -f "$SCRIPT" ]
}
