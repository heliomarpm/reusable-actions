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

@test "release: bump PATCH para commits do tipo fix" {
  echo "v1.0.0" > version.txt
  git add version.txt
  git commit -m "chore: initial release" >/dev/null 2>&1
  git tag -a "v1.0.0" -m "v1.0.0"

  echo "patch" >> version.txt
  git add version.txt
  git commit -m "fix: resolver bug critico" >/dev/null 2>&1

  export INPUT_BRANCH="main"
  export RELEASE_BRANCHES="main"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github_output.txt"
  touch "$GITHUB_OUTPUT"

  run bash "$ROOT_DIR/scripts/shared/release/run.sh"
  [ "$status" -eq 0 ]

  run grep -F "version=v1.0.1" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep -F "tag=v1.0.1" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "release: bump MINOR para commits do tipo feat" {
  echo "v1.0.0" > version.txt
  git add version.txt
  git commit -m "chore: initial release" >/dev/null 2>&1
  git tag -a "v1.0.0" -m "v1.0.0"

  echo "feat" >> version.txt
  git add version.txt
  git commit -m "feat: adicionar nova funcionalidade" >/dev/null 2>&1

  export INPUT_BRANCH="main"
  export RELEASE_BRANCHES="main"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github_output.txt"
  touch "$GITHUB_OUTPUT"

  run bash "$ROOT_DIR/scripts/shared/release/run.sh"
  [ "$status" -eq 0 ]

  run grep -F "version=v1.1.0" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep -F "tag=v1.1.0" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "release: bump MAJOR para breaking changes" {
  echo "v1.0.0" > version.txt
  git add version.txt
  git commit -m "chore: initial release" >/dev/null 2>&1
  git tag -a "v1.0.0" -m "v1.0.0"

  echo "breaking" >> version.txt
  git add version.txt
  git commit -m "feat!: quebra de compatibilidade na API" >/dev/null 2>&1

  export INPUT_BRANCH="main"
  export RELEASE_BRANCHES="main"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github_output.txt"
  touch "$GITHUB_OUTPUT"

  run bash "$ROOT_DIR/scripts/shared/release/run.sh"
  [ "$status" -eq 0 ]

  run grep -F "version=v2.0.0" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep -F "tag=v2.0.0" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "release: gera tag de pré-release RC em release branch" {
  echo "v1.0.0" > version.txt
  git add version.txt
  git commit -m "chore: v1.0.0" >/dev/null 2>&1
  git tag -a "v1.0.0" -m "v1.0.0"

  echo "rc" >> version.txt
  git add version.txt
  git commit -m "feat: nova feature para release 1.1.0" >/dev/null 2>&1

  export INPUT_BRANCH="release-1.1.0"
  export PRERELEASE_STRATEGY="rc"
  export PRERELEASE_SUFFIX="rc"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github_output.txt"
  touch "$GITHUB_OUTPUT"

  run bash "$ROOT_DIR/scripts/shared/release/run.sh"
  [ "$status" -eq 0 ]

  run grep -F "version=v1.1.0-rc.1" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep -F "tag=v1.1.0-rc.1" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}

@test "release: promove RC para release estável na branch main" {
  echo "v1.0.0" > version.txt
  git add version.txt
  git commit -m "chore: v1.0.0" >/dev/null 2>&1
  git tag -a "v1.0.0" -m "v1.0.0"

  # Cria tag anterior RC
  echo "rc" >> version.txt
  git add version.txt
  git commit -m "feat: preparar 1.1.0" >/dev/null 2>&1
  git tag -a "v1.1.0-rc.1" -m "v1.1.0-rc.1"

  # Merge final na main
  echo "final" >> version.txt
  git add version.txt
  git commit -m "chore: finalizar release 1.1.0" >/dev/null 2>&1

  export INPUT_BRANCH="main"
  export RELEASE_BRANCHES="main"
  export GITHUB_OUTPUT="$TEST_TMPDIR/github_output.txt"
  touch "$GITHUB_OUTPUT"

  run bash "$ROOT_DIR/scripts/shared/release/run.sh"
  [ "$status" -eq 0 ]

  # Deve limpar o sufixo -rc.1 e gerar a estável v1.1.0
  run grep -F "version=v1.1.0" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]

  run grep -F "tag=v1.1.0" "$GITHUB_OUTPUT"
  [ "$status" -eq 0 ]
}
