#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  export REUSABLE_PATH="$ROOT_DIR"
  
  # Carrega os helpers
  source "$ROOT_DIR/scripts/shared/shell-helpers.sh"
  
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "shell-helpers: log() emite mensagem no stderr com prefixo '→'" {
  run log "teste de log"
  [ "$status" -eq 0 ]
  [ "$output" = "→ teste de log" ]
}

@test "shell-helpers: notice() formata anotação ::notice::" {
  run notice "mensagem informativa"
  [ "$status" -eq 0 ]
  [ "$output" = "::notice::mensagem informativa" ]
}

@test "shell-helpers: warn() formata anotação ::warning::" {
  run warn "mensagem de aviso"
  [ "$status" -eq 0 ]
  [ "$output" = "::warning::mensagem de aviso" ]
}

@test "shell-helpers: fail() emite ::error:: e aborta com exit code 1" {
  run fail "erro critico"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "::error::erro critico" ]]
}

@test "shell-helpers: has_file() valida corretamente existência de arquivos" {
  touch "$TEST_TMPDIR/existe.txt"
  run has_file "$TEST_TMPDIR/existe.txt"
  [ "$status" -eq 0 ]

  run has_file "$TEST_TMPDIR/nao_existe.txt"
  [ "$status" -ne 0 ]
}

@test "shell-helpers: render_template() interpola variáveis corretamente" {
  local tpl="$TEST_TMPDIR/sample.md"
  local out="$TEST_TMPDIR/rendered.md"

  echo "Status: {{STATUS}} | Versao: {{VERSION}} | NaoMudou: {{FIXO}}" > "$tpl"

  render_template "$tpl" "$out" \
    STATUS "Aprovado" \
    VERSION "v1.2.3" \
    FIXO "Constante"

  [ -f "$out" ]
  local result
  result="$(cat "$out")"
  [ "$result" = "Status: Aprovado | Versao: v1.2.3 | NaoMudou: Constante" ]
}

@test "shell-helpers: append_template_to_summary() anexa conteúdo ao GITHUB_STEP_SUMMARY" {
  local tpl="$TEST_TMPDIR/summary_test.md"
  echo "## Summary: {{TITLE}}" > "$tpl"

  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  append_template_to_summary "$tpl" TITLE "Execucao Concluida"

  local content
  content="$(cat "$GITHUB_STEP_SUMMARY")"
  [ "$content" = "## Summary: Execucao Concluida" ]
}

@test "shell-helpers: resolve_project_path() retorna raiz quando input for '.'" {
  export GITHUB_WORKSPACE="$TEST_TMPDIR"
  local resolved
  resolved="$(resolve_project_path ".")"
  [ "$resolved" = "$TEST_TMPDIR" ]
}

@test "shell-helpers: resolve_project_path() detecta subpasta única com manifesto" {
  export GITHUB_WORKSPACE="$TEST_TMPDIR"
  mkdir -p "$TEST_TMPDIR/subapp"
  echo '{"name": "subapp"}' > "$TEST_TMPDIR/subapp/package.json"

  local resolved
  resolved="$(resolve_project_path "")"
  [ "$resolved" = "$TEST_TMPDIR/subapp" ]
}
