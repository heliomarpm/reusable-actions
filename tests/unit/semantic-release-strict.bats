#!/usr/bin/env bats

setup() {
  TESTS_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  export REUSABLE_PATH="$ROOT_DIR"
  export BASH_ENV="$ROOT_DIR/scripts/shared/shell-helpers.sh"
  export SKIP_TOOLCHAIN_INSTALL="true"
  
  TEST_TMPDIR="$(mktemp -d)"
  cd "$TEST_TMPDIR"
  
  git init -b main >/dev/null 2>&1
  git config user.name "Tester"
  git config user.email "tester@example.com"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "strict-mode: falha e bloqueia pipeline quando commit for não-convencional" {
  echo "codigo" > file.txt
  git add file.txt
  git commit -m "ajustes no codigo e correcoes gerais" >/dev/null 2>&1

  export STRICT_CONVENTIONAL_COMMITS="true"
  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  run bash -c "source '$ROOT_DIR/scripts/shared/semantic-release/run.sh'; strict_mode"
  [ "$status" -eq 1 ]

  run grep -F "Release bloqueada por STRICT MODE" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]

  run grep -F "ajustes no codigo e correcoes gerais" "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
}

@test "strict-mode: passa com sucesso na validação quando commit for do tipo ci, chore ou docs" {
  echo "codigo" > file.txt
  git add file.txt
  git commit -m "ci: atualizar workflow de automacao" >/dev/null 2>&1

  export STRICT_CONVENTIONAL_COMMITS="true"
  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  run bash -c "source '$ROOT_DIR/scripts/shared/semantic-release/run.sh'; strict_mode"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Conventional commits validation passed" ]]
}

@test "strict-mode: passa com sucesso na validação para commits do tipo feat e fix" {
  echo "codigo" > file.txt
  git add file.txt
  git commit -m "feat(auth): implementar suporte a MFA" >/dev/null 2>&1

  export STRICT_CONVENTIONAL_COMMITS="true"
  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  run bash -c "source '$ROOT_DIR/scripts/shared/semantic-release/run.sh'; strict_mode"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Conventional commits validation passed" ]]
}

@test "strict-mode: tolera emojis shortcodes no início da mensagem (ex: :sparkles: feat:)" {
  echo "codigo" > file.txt
  git add file.txt
  git commit -m ":sparkles: feat: adicionar funcionalidade com shortcode" >/dev/null 2>&1

  export STRICT_CONVENTIONAL_COMMITS="true"
  export GITHUB_STEP_SUMMARY="$TEST_TMPDIR/summary.md"
  touch "$GITHUB_STEP_SUMMARY"

  run bash -c "source '$ROOT_DIR/scripts/shared/semantic-release/run.sh'; strict_mode"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Conventional commits validation passed" ]]
}
