#!/usr/bin/env bash
set -euo pipefail

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
    local root_manifest=false
    for f in "$workspace/package.json" "$workspace/composer.json" "$workspace/requirements.txt" "$workspace/go.mod"; do
      if [[ -f "$f" ]]; then
        root_manifest=true
        break
      fi
    done
    if [[ "$root_manifest" == "false" ]]; then
      local dotnet_files=("$workspace"/*.csproj "$workspace"/*.sln)
      if [[ -f "${dotnet_files[0]:-}" ]]; then
        root_manifest=true
      fi
    fi

    if [[ "$root_manifest" == "false" ]]; then
      local sub_manifests=()
      for f in "$workspace"/*/package.json "$workspace"/*/composer.json "$workspace"/*/requirements.txt "$workspace"/*/go.mod "$workspace"/*/*.csproj; do
        if [[ -f "$f" ]]; then
          local dir="${f%/*}"
          local base_dir="${dir##*/}"
          if [[ "$base_dir" != "node_modules" && "$base_dir" != "__reusable_actions__" && "$base_dir" != ".github" && "$base_dir" != "vendor" ]]; then
            sub_manifests+=("$dir")
          fi
        fi
      done

      local unique_dirs=($(echo "${sub_manifests[@]:-}" | tr ' ' '\n' | sort -u))
      if [[ ${#unique_dirs[@]} -eq 1 && -n "${unique_dirs[0]:-}" ]]; then
        resolved="${unique_dirs[0]}"
        log "💡 Auto-detected project directory: ${resolved#$workspace/}"
      else
        resolved="$workspace"
      fi
    else
      resolved="$workspace"
    fi
  else
    resolved="$workspace/$raw"
  fi

  if [[ ! -d "$resolved" ]]; then
    fail "❌ Project path does not exist: $resolved"
  fi

  echo "$resolved"
}

# ────────────────────────────────────────
# Validação do repositório Git
# ────────────────────────────────────────
validate_git_repository() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "❌ O diretório '$(pwd)' não é um repositório Git. Certifique-se de incluir o step 'actions/checkout@v4' com 'fetch-depth: 0' no seu workflow antes de executar esta action!"
  fi

  # Alerta se o repositório for shallow clone
  if [[ "$(git rev-parse --is-shallow-repository 2>/dev/null || true)" == "true" ]]; then
    log "⚠️ Repositório clonado como shallow (incompleto). Recomendamos configurar 'fetch-depth: 0' no step 'actions/checkout@v4' para permitir leitura total do histórico e tags."
  fi
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
  local SCRIPT_NAME="${0##*/}"
  local MARKER_FILE="${RUNNER_TEMP:-/tmp}/.shell_error_reported_${GITHUB_RUN_ID:-local}"

  # Emite anotação nativa do GitHub Actions
  echo "::error title=Shell script failed ($SCRIPT_NAME)::Command '$CMD' failed with exit code ${EXIT_CODE}"

  # Deduplicação: se a falha já foi reportada neste job, não duplica no GITHUB_STEP_SUMMARY
  if [[ -f "$MARKER_FILE" ]]; then
    exit "$EXIT_CODE"
  fi
  touch "$MARKER_FILE" 2>/dev/null || true

  # Se for um script temporário inline do runner (ex: UUID.sh), substitui pelo nome amigável
  if [[ "$SCRIPT_NAME" =~ ^[0-9a-fA-F-]{32,}\.sh$ ]]; then
    SCRIPT_NAME="Workflow step"
  fi

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo "### ❌ Shell Script Failure"
      echo ""
      echo "- **Script:** \`$SCRIPT_NAME\`"
      echo "- **Command:** \`$CMD\`"
      echo "- **Exit code:** \`$EXIT_CODE\`"
      echo ""
    } >> "$GITHUB_STEP_SUMMARY"
  fi

  exit "$EXIT_CODE"
}
trap on_error ERR
