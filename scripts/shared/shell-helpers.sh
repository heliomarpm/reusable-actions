#!/usr/bin/env bash
set -Eeuo pipefail

# Guard contra execução dupla
[[ -n "${__SHELL_HELPERS_LOADED:-}" ]] && return 0
__SHELL_HELPERS_LOADED=true

# ────────────────────────────────────────
# Logging (apenas stderr para não poluir stdout)
# ────────────────────────────────────────
log()    { echo "→ $*" >&2; }
notice() { echo "::notice::$*"; }
warn()   { echo "::warning::$*"; }

# ────────────────────────────────────────
# Assertions
# ────────────────────────────────────────
has_file() { [[ -f "$1" ]]; }

fail() {
  echo "::error::$*" >&2
  exit 1
}

require_env() {
  local VAR="$1"
  if [[ -z "${!VAR:-}" ]]; then
    fail "Required environment variable not set: $VAR"
  fi
}

# ────────────────────────────────────────
# File system
# ────────────────────────────────────────
ls_files() {
  echo "📂 $(pwd)" >&2
  ls -la >&2
}

resolve_project_path() {
  local raw="${1:-.}"
  local workspace="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE not set}"

  raw="${raw#./}"
  raw="${raw#/}"
  raw="${raw%/}"

  local resolved
  if [[ -z "$raw" || "$raw" == "." ]]; then
    resolved="$workspace"
  else
    resolved="$workspace/$raw"
  fi

  if [[ ! -d "$resolved" ]]; then
    fail "❌ Project path does not exist: $resolved"
  fi

  echo "$resolved"
}

# ────────────────────────────────────────
# Summary helpers
# ────────────────────────────────────────
summary_section() { { echo "## $1"; echo ""; } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; }
summary_kv()      { echo "- **$1:** $2" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; }
summary_line()    { echo "$1" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; }
summary_blank()   { echo "" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; }
summary_success() { summary_section "✅ Success"; summary_line "$1"; }
summary_failure() { summary_section "❌ Failure"; summary_line "$1"; }

# ────────────────────────────────────────
# Template Rendering helpers
# ────────────────────────────────────────
render_template() {
  local template_file="${1:-}"
  local output_file="${2:-}"
  shift 2 || true

  [[ -f "$template_file" ]] || fail "Template file not found: $template_file"

  local content
  content="$(cat "$template_file")"

  while [[ $# -ge 2 ]]; do
    local key="$1"
    local val="${2:-}"
    shift 2
    content="${content//\{\{${key}\}\}/$val}"
  done

  echo "$content" > "$output_file"
}

append_template_to_summary() {
  local template_file="$1"
  shift
  local temp_rendered
  temp_rendered="$(mktemp)"
  render_template "$template_file" "$temp_rendered" "$@"
  cat "$temp_rendered" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  rm -f "$temp_rendered"
}

# ────────────────────────────────────────
# Error trap
# ────────────────────────────────────────
on_error() {
  local EXIT_CODE=$?
  local CMD="${BASH_COMMAND:-unknown}"
  echo "::error title=Shell script failed::Command failed with exit code ${EXIT_CODE}"
  {
    echo "## ❌ Shell Script Failure"
    echo ""
    echo "**Command:** \`$CMD\`"
    echo "**Exit code:** \`$EXIT_CODE\`"
    echo "**Script:** \`${0##*/}\`"
  } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
  exit "$EXIT_CODE"
}
trap on_error ERR
