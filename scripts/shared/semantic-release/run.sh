#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Semantic Release Script"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() { echo "→ $1"; }
has_file() { [[ -f "$1" ]]; }

fail() {
  echo "::error::$1"
  exit 1
}


# ------------------------------------------------------------
# Environments
# ------------------------------------------------------------
REUSABLE_PATH="${REUSABLE_PATH:-.}"
STACK="${STACK:-node}"
IS_DRY_RUN="${SEMANTIC_RELEASE_DRY_RUN:-false}"
IS_DEBUG_MODE="${SEMANTIC_RELEASE_DEBUG_MODE:-false}"
STRICT_MODE="${STRICT_CONVENTIONAL_COMMITS:-false}"

CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/semantic-release/resolve-custom-releaserc.sh" "${SEMANTIC_RELEASE_CONFIG:-}")
DEFAULT_CONFIG="./$REUSABLE_PATH/scripts/plugins/$STACK/releaserc.json"
STRICT_TEMPLATE="$REUSABLE_PATH/templates/strict-mode-error.md"

bash "$REUSABLE_PATH/scripts/shared/semantic-release/install.sh"

# ------------------------------------------------------------
# Build semantic-release command
# ------------------------------------------------------------
build_cmd() {
  local CMD="npx semantic-release"

  if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
    log "Running semantic-release with consumer config"
    CMD+=" --extends $CUSTOM_CONFIG_PATH"
  else
    [[ -f "$DEFAULT_CONFIG" ]] || fail "Default config not found for stack: $STACK"

    log "Running semantic-release with default config"
    CMD+=" --extends $DEFAULT_CONFIG"
  fi

  if [[ "$IS_DEBUG_MODE" == "true" ]]; then
    log "Debug mode enabled"
    CMD+=" --debug"
  fi
  
  echo "$CMD" 
}

# ------------------------------------------------------------
# STRICT MODE — Enforce conventional commits
# ------------------------------------------------------------
strict_mode() {
  local STRICT_CMD="${1:-npx semantic-release} --dry-run"
  
  log "Strict mode enabled — validating conventional commits"

  OUTPUT=$(eval "$STRICT_CMD" 2>&1 || true)

  if echo "$OUTPUT" | grep -qiE "no release type found|There are no relevant changes"; then

    # Annotation (curta, visível no PR / Job)
    echo "::error title=RELEASE BLOCKED (STRICT MODE)::No valid Conventional Commits found since the last release. See job summary for instructions."

    # Job Summary (markdown completo)
    {
      echo "# 🚫 Release bloqueada por STRICT MODE"
      echo ""
      echo "**Repositório:** \`$GITHUB_REPOSITORY\`"
      echo "**Branch:** \`${GITHUB_REF_NAME:-unknown}\`"
      echo ""
      echo "❌ Nenhum **Conventional Commit** válido foi encontrado desde o último release."
      echo ""
      echo "---"
    } >> "$GITHUB_STEP_SUMMARY"

    if [[ -f "$STRICT_TEMPLATE" ]]; then
      cat "$STRICT_TEMPLATE" >> "$GITHUB_STEP_SUMMARY"
    else
      echo "📖 Veja [Conventional Commits specification](https://www.conventionalcommits.org)" >> "$GITHUB_STEP_SUMMARY"
    fi

    exit 1
  fi

  log "Conventional commits validation passed"
}

# ------------------------------------------------------------
# Run release
# ------------------------------------------------------------
run() {
  CMD=$(build_cmd)

  if [[ "$STRICT_MODE" == "true" ]]; then
    strict_mode "$CMD"
  fi

  if [[ "$IS_DRY_RUN" == "true" || "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
    log "Dry-run enabled"
    CMD+=" --dry-run"
  fi
  
  log "🚀 Running: $CMD"
  eval "$CMD"  
}

run
log "🎉 Done."

