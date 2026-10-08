#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  HELPERS="$ROOT_DIR/scripts/shared/shell-helpers.sh"
}

@test "pr/skip-quality-gate: templates existem e possuem formato esperado" {
  [ -f "$ROOT_DIR/templates/pr-quality-gate-skipped.md" ]
  [ -f "$ROOT_DIR/templates/summary-quality-gate-skipped.md" ]

  run grep -q "Quality Gate ignorado" "$ROOT_DIR/templates/pr-quality-gate-skipped.md"
  [ "$status" -eq 0 ]

  run grep -q "skip-quality-gate: true" "$ROOT_DIR/templates/summary-quality-gate-skipped.md"
  [ "$status" -eq 0 ]
}

@test "pr/skip-quality-gate: append_template_to_summary renderiza resumo no GITHUB_STEP_SUMMARY" {
  source "$HELPERS"
  export GITHUB_STEP_SUMMARY="$(mktemp)"

  append_template_to_summary "$ROOT_DIR/templates/summary-quality-gate-skipped.md"
  
  run grep -q "Quality Gate ignorado (\`skip-quality-gate: true\`)" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  rm -f "$GITHUB_STEP_SUMMARY"
}

@test "pr/skip-quality-gate: mapeamento de labels e bloco em create-pr com status skipped" {
  source "$HELPERS"
  STATUS="skipped"
  TEMPLATES_DIR="$ROOT_DIR/templates"

  # Replica a lógica de actions/create-pr/action.yml
  case "$STATUS" in
    failed)  ADD="coverage-failed";  DEL="coverage-passed,coverage-missing" ;;
    passed)  ADD="coverage-passed";  DEL="coverage-failed,coverage-missing" ;;
    missing) ADD="coverage-missing"; DEL="coverage-passed,coverage-failed"  ;;
    skipped) ADD="";                 DEL="coverage-passed,coverage-failed,coverage-missing" ;;
    *)       ADD=""; DEL="" ;;
  esac

  [ "$ADD" = "" ]
  [ "$DEL" = "coverage-passed,coverage-failed,coverage-missing" ]

  QUALITY_BLOCK_TMP="$(mktemp)"
  if [[ "$STATUS" == "skipped" ]]; then
    if [[ -f "$TEMPLATES_DIR/pr-quality-gate-skipped.md" ]]; then
      render_template "$TEMPLATES_DIR/pr-quality-gate-skipped.md" "$QUALITY_BLOCK_TMP"
    fi
  fi

  run grep -q "Quality Gate ignorado" "$QUALITY_BLOCK_TMP"
  [ "$status" -eq 0 ]
  rm -f "$QUALITY_BLOCK_TMP"
}

@test "pr/skip-quality-gate: workflow cd-pull-request declara input skip-quality-gate e condições" {
  WORKFLOW="$ROOT_DIR/.github/workflows/cd-pull-request.yml"
  [ -f "$WORKFLOW" ]

  run grep -q "skip-quality-gate:" "$WORKFLOW"
  [ "$status" -eq 0 ]

  run grep -q "inputs.skip-quality-gate != true" "$WORKFLOW"
  [ "$status" -eq 0 ]

  run grep -q "!failure() && !cancelled()" "$WORKFLOW"
  [ "$status" -eq 0 ]
}
