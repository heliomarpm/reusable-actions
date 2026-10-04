#!/usr/bin/env bash
set -Eeuo pipefail

# Carrega helpers (se não carregado via BASH_ENV)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shell-helpers.sh"

log "🚀 Semantic Release Script"

# ------------------------------------------------------------
# Environments
# ------------------------------------------------------------
REUSABLE_PATH="${REUSABLE_PATH:-.}"
STACK="${STACK:-}"
PROJECT_PATH="${PROJECT_PATH:-.}"
export PROJECT_PATH

# Auto-detect stack if not provided
if [[ -z "$STACK" ]]; then
  DETECT_STACK_SCRIPT="$REUSABLE_PATH/scripts/shared/detect-stack.sh"
  if [[ -f "$DETECT_STACK_SCRIPT" ]]; then
    STACK=$(bash "$DETECT_STACK_SCRIPT" 2>/dev/null || true)
  fi
fi
STACK="${STACK:-node}"

IS_DRY_RUN="${SEMANTIC_RELEASE_DRY_RUN:-false}"
IS_DEBUG_MODE="${SEMANTIC_RELEASE_DEBUG_MODE:-false}"
STRICT_MODE="${STRICT_CONVENTIONAL_COMMITS:-false}"

CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/semantic-release/resolve-custom-releaserc.sh" "${SEMANTIC_RELEASE_CONFIG:-}")
if [[ -n "$CUSTOM_CONFIG_PATH" && ! -f "$CUSTOM_CONFIG_PATH" ]]; then
  log "⚠️ Config path returned is not a valid file: $CUSTOM_CONFIG_PATH"
  CUSTOM_CONFIG_PATH=""
fi

GENERIC_CONFIG="$REUSABLE_PATH/scripts/shared/semantic-release/default-releaserc.json"
PLUGIN_CONFIG_JS="$REUSABLE_PATH/scripts/plugins/$STACK/releaserc.js"
PLUGIN_CONFIG_JSON="$REUSABLE_PATH/scripts/plugins/$STACK/releaserc.json"

if [[ -n "$STACK" && -f "$PLUGIN_CONFIG_JS" ]]; then
  DEFAULT_CONFIG="$PLUGIN_CONFIG_JS"
elif [[ -n "$STACK" && -f "$PLUGIN_CONFIG_JSON" ]]; then
  DEFAULT_CONFIG="$PLUGIN_CONFIG_JSON"
else
  DEFAULT_CONFIG="$GENERIC_CONFIG"
fi
STRICT_TEMPLATE="$REUSABLE_PATH/templates/strict-mode-error.md"

bash "$REUSABLE_PATH/scripts/shared/semantic-release/install.sh"

# ------------------------------------------------------------
# Build semantic-release command
# ------------------------------------------------------------
CMD=(npx semantic-release)

if [[ -n "$CUSTOM_CONFIG_PATH" && -f "$CUSTOM_CONFIG_PATH" ]]; then
  log "Running semantic-release with consumer config: $CUSTOM_CONFIG_PATH"
  CMD+=(--extends "$CUSTOM_CONFIG_PATH")
else
  [[ -f "$DEFAULT_CONFIG" ]] || fail "Default config not found for stack: $STACK ($DEFAULT_CONFIG)"

  log "Running semantic-release with default config: $DEFAULT_CONFIG"
  CMD+=(--extends "$DEFAULT_CONFIG")
fi

if [[ "$IS_DEBUG_MODE" == "true" ]]; then
  log "Debug mode enabled"
  CMD+=(--debug)
fi

log "Custom Path detected: ${CUSTOM_CONFIG_PATH:-<none>}"
log "Default Path detected: $DEFAULT_CONFIG"
log "Dry run enabled: $IS_DRY_RUN"
log "Strict Mode enabled: $STRICT_MODE"

# ------------------------------------------------------------
# STRICT MODE — Enforce conventional commits
# ------------------------------------------------------------
strict_mode() {
  local STRICT_CMD=("$@")
  STRICT_CMD+=(--dry-run)
  
  log "Strict mode enabled — validating conventional commits"

  OUTPUT=$("${STRICT_CMD[@]}" 2>&1 || true)

  if echo "$OUTPUT" | grep -qiE "no release type found|There are no relevant changes"; then
    echo "::error title=RELEASE BLOCKED (STRICT MODE)::No valid Conventional Commits found since the last release. See job summary for instructions."

    {
      echo "# 🚫 Release bloqueada por STRICT MODE"
      echo ""
      echo "**Repositório:** \`$GITHUB_REPOSITORY\`"
      echo "**Branch:** \`${GITHUB_REF_NAME:-unknown}\`"
      echo ""
      echo "❌ Nenhum **Conventional Commit** válido foi encontrado desde o último release."
      echo ""
      echo "---"
    } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

    if [[ -f "$STRICT_TEMPLATE" ]]; then
      cat "$STRICT_TEMPLATE" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    else
      echo "📖 Veja [Conventional Commits specification](https://www.conventionalcommits.org)" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    fi

    exit 1
  fi

  log "Conventional commits validation passed"
}

# ------------------------------------------------------------
# Run release
# ------------------------------------------------------------
run() {
  if [[ "$STRICT_MODE" == "true" ]]; then
    strict_mode "${CMD[@]}"
  fi

  if [[ "$IS_DRY_RUN" == "true" || "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
    log "Dry-run enabled"
    CMD+=(--dry-run)
  fi
  
  log "🚀 Running: ${CMD[*]}"
  "${CMD[@]}"
}

run
log "🎉 Done."
