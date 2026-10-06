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
BRANCH="${BRANCH:-}"
export PRERELEASE_STRATEGY="${PRERELEASE_STRATEGY:-rc}"
export PRERELEASE_SUFFIX="${PRERELEASE_SUFFIX:-rc}"
RUN_LOG=""

if [[ -n "$BRANCH" ]]; then
  export GITHUB_REF="refs/heads/$BRANCH"
  export GITHUB_REF_NAME="$BRANCH"
  git checkout "$BRANCH" 2>/dev/null || true
  log "🌿 Semantic Release target branch set to: $BRANCH"
fi

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

  RUN_LOG="$(mktemp)"
  trap 'rm -f "${RUN_LOG:-}"' EXIT

  set +e
  "${CMD[@]}" 2>&1 | tee "$RUN_LOG"
  local CMD_EXIT="${PIPESTATUS[0]}"
  set -e

  # Se o comando falhou
  if [[ "$CMD_EXIT" -ne 0 ]]; then
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
      append_template_to_summary "summary-release-failed.md" \
        REPOSITORY "${GITHUB_REPOSITORY:-unknown}" \
        BRANCH "${GITHUB_REF_NAME:-unknown}" \
        ENGINE "Semantic Release ($STACK)" \
        EXIT_CODE "$CMD_EXIT"
    fi
    exit "$CMD_EXIT"
  fi

  # Extrai informações do log
  local NEXT_VERSION=""
  NEXT_VERSION="$(grep -Eo 'The next release version is [0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?|Published release [0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?' "$RUN_LOG" | sed -E 's/.* (([0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?))/\1/' | head -n1 || true)"
  if [[ -z "$NEXT_VERSION" ]]; then
    NEXT_VERSION="$(grep -Eo 'next release version is ([0-9]+\.[0-9]+\.[0-9]+)' "$RUN_LOG" | sed -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+)/\1/' | head -n1 || true)"
  fi

  local LAST_VERSION=""
  LAST_VERSION="$(grep -Eo 'Found git tag [^ ]+ associated with version [0-9]+\.[0-9]+\.[0-9]+' "$RUN_LOG" | sed -E 's/.* version ([0-9]+\.[0-9]+\.[0-9]+)/\1/' | head -n1 || true)"
  if [[ -z "$LAST_VERSION" ]]; then
    local LAST_TAG_RAW
    LAST_TAG_RAW="$(git describe --tags --abbrev=0 2>/dev/null || true)"
    LAST_VERSION="${LAST_TAG_RAW#v}"
  fi

  local RELEASE_TYPE=""
  RELEASE_TYPE="$(grep -Eo 'Analysis of [0-9]+ commits complete: ([a-z]+) release' "$RUN_LOG" | sed -E 's/.*: ([a-z]+) release/\1/' | head -n1 || true)"
  RELEASE_TYPE="${RELEASE_TYPE:-patch}"

  local REPO_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}"
  local COMMIT_SHA
  COMMIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo '')"
  local CURRENT_BRANCH="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')}"

  local NEXT_TAG=""
  local LAST_TAG=""
  [[ -n "$NEXT_VERSION" ]] && NEXT_TAG="v$NEXT_VERSION"
  [[ -n "$LAST_VERSION" ]] && LAST_TAG="v$LAST_VERSION"

  local RELEASE_URL=""
  local COMPARE_URL=""
  local LAST_TAG_URL=""
  local COMMIT_URL=""
  if [[ -n "$REPO_URL" && -n "${GITHUB_REPOSITORY:-}" ]]; then
    [[ -n "$NEXT_TAG" ]] && RELEASE_URL="${REPO_URL}/releases/tag/${NEXT_TAG}"
    [[ -n "$LAST_TAG" ]] && LAST_TAG_URL="${REPO_URL}/releases/tag/${LAST_TAG}"
    [[ -n "$LAST_TAG" && -n "$NEXT_TAG" && "$LAST_TAG" != "$NEXT_TAG" ]] && COMPARE_URL="${REPO_URL}/compare/${LAST_TAG}...${NEXT_TAG}"
    [[ -n "$COMMIT_SHA" ]] && COMMIT_URL="${REPO_URL}/commit/${COMMIT_SHA}"
  fi

  # Outputs para GitHub Actions
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "version=$NEXT_VERSION" >> "$GITHUB_OUTPUT"
    echo "tag=$NEXT_TAG" >> "$GITHUB_OUTPUT"
    echo "last_version=$LAST_VERSION" >> "$GITHUB_OUTPUT"
    echo "last_tag=$LAST_TAG" >> "$GITHUB_OUTPUT"
    echo "release_type=$RELEASE_TYPE" >> "$GITHUB_OUTPUT"
    echo "published=$([[ -n "$NEXT_VERSION" && "$IS_DRY_RUN" != "true" ]] && echo 'true' || echo 'false')" >> "$GITHUB_OUTPUT"
  fi

  # Geração do GITHUB_STEP_SUMMARY via templates
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    local EXTRA_METADATA
    EXTRA_METADATA=$(cat <<EOF
| **Stack** | \`$STACK\` |
| **Project Path** | \`$PROJECT_PATH\` |
EOF
)

    if [[ -n "$NEXT_VERSION" && "$IS_DRY_RUN" != "true" ]]; then
      local NEW_VERSION_CELL="\`$NEXT_TAG\`"
      [[ -n "$RELEASE_URL" ]] && NEW_VERSION_CELL="[**\`$NEXT_TAG\`**]($RELEASE_URL)"

      local LAST_VERSION_CELL="_(Primeira release)_"
      if [[ -n "$LAST_TAG_URL" ]]; then
        LAST_VERSION_CELL="[**\`$LAST_TAG\`**]($LAST_TAG_URL)"
      elif [[ -n "$LAST_TAG" ]]; then
        LAST_VERSION_CELL="\`$LAST_TAG\`"
      fi

      local COMMIT_CELL="\`$COMMIT_SHA\`"
      [[ -n "$COMMIT_URL" ]] && COMMIT_CELL="[\`$COMMIT_SHA\`]($COMMIT_URL)"

      local QUICK_LINKS=""
      if [[ -n "$RELEASE_URL" || -n "$COMPARE_URL" ]]; then
        local LNK_REL=""
        local LNK_CMP=""
        [[ -n "$RELEASE_URL" ]] && LNK_REL="- 📦 [Visualizar Release no GitHub]($RELEASE_URL)"
        [[ -n "$COMPARE_URL" ]] && LNK_CMP="- 🔍 [Comparar Alterações com a Release Anterior (\`$LAST_TAG...$NEXT_TAG\`)]($COMPARE_URL)"
        QUICK_LINKS=$(cat <<EOF
### 🔗 Links Rápidos
$LNK_REL
$LNK_CMP
EOF
)
      fi

      local STATUS_TEXT="🟢 **Publicada no GitHub**"
      if [[ "$CURRENT_BRANCH" =~ ^release[-/] ]]; then
        STATUS_TEXT="🟡 **Pre-Release Publicada no GitHub**"
      fi

      append_template_to_summary "summary-release-published.md" \
        STATUS "$STATUS_TEXT" \
        NEW_VERSION "$NEW_VERSION_CELL" \
        LAST_VERSION "$LAST_VERSION_CELL" \
        RELEASE_TYPE "$RELEASE_TYPE" \
        CURRENT_BRANCH "$CURRENT_BRANCH" \
        COMMIT "$COMMIT_CELL" \
        EXTRA_METADATA "$EXTRA_METADATA" \
        QUICK_LINKS "$QUICK_LINKS" \
        RELEASE_NOTES ""

    elif [[ -n "$NEXT_VERSION" && "$IS_DRY_RUN" == "true" ]]; then
      append_template_to_summary "summary-release-dryrun.md" \
        NEXT_TAG "$NEXT_TAG" \
        LAST_TAG "${LAST_TAG:-N/A}" \
        RELEASE_TYPE "$RELEASE_TYPE" \
        CURRENT_BRANCH "$CURRENT_BRANCH" \
        EXTRA_METADATA "$EXTRA_METADATA"

    else
      local LAST_VERSION_CELL="_(Nenhuma tag encontrada)_"
      if [[ -n "$LAST_TAG_URL" ]]; then
        LAST_VERSION_CELL="[**\`$LAST_TAG\`**]($LAST_TAG_URL)"
      elif [[ -n "$LAST_TAG" ]]; then
        LAST_VERSION_CELL="\`$LAST_TAG\`"
      fi

      local EXPLANATION
      EXPLANATION=$(cat <<EOF
Todos os commits enviados desde a tag \`${LAST_TAG:-inicial}\` foram do tipo sem impacto no SemVer (ex: \`docs:\`, \`chore:\`, \`ci:\`, \`test:\`, \`refactor:\`).
> 👉 Para gerar uma nova release, envie commits com prefixo \`feat:\` (minor) ou \`fix:\` (patch).
EOF
)

      append_template_to_summary "summary-release-skipped.md" \
        LAST_VERSION "$LAST_VERSION_CELL" \
        CURRENT_BRANCH "$CURRENT_BRANCH" \
        EXTRA_METADATA "$EXTRA_METADATA" \
        REASON "Nenhum commit com impacto semântico foi encontrado desde o último release." \
        EXPLANATION "$EXPLANATION" \
        LAST_TAG "${LAST_TAG:-inicial}"
    fi
  fi

  rm -f "${RUN_LOG:-}"
  trap - EXIT
}

run
log "🎉 Done."
