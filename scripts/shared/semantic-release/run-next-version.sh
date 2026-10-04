#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "$0")/../shell-helpers.sh"
log "🔍 Resolving next release version (semantic-release dry-run)"

REUSABLE_PATH="${REUSABLE_PATH:-.}"
# CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/semantic-release/resolve-custom-releaserc.sh" "${SEMANTIC_RELEASE_CONFIG:-}")
CUSTOM_CONFIG_PATH=$(bash "$(dirname "$0")/resolve-custom-releaserc.sh" "${SEMANTIC_RELEASE_CONFIG:-}")
STRICT="${STRICT_CONVENTIONAL_COMMITS:-false}"

STRICT_TEMPLATE="$REUSABLE_PATH/templates/strict-mode-error.md"

bash "$(dirname "$0")/install.sh"
# bash "$REUSABLE_PATH/scripts/shared/semantic-release/install.sh"

# ------------------------------------------------------------
# STRICT MODE — Enforce conventional commits
# ------------------------------------------------------------
summary_strict_mode() {
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
  fi

  fail "Release blocked by STRICT MODE: no valid Conventional Commits found"
}



CMD="npx semantic-release --dry-run --debug"
[[ -n "$CUSTOM_CONFIG_PATH" && -f "$CUSTOM_CONFIG_PATH" ]] && CMD+=" --extends $CUSTOM_CONFIG_PATH"

OUTPUT=$(eval "$CMD" 2>&1 || true)


# ------------------------------------------------------------
# STRICT MODE
# ------------------------------------------------------------
if [[ "$STRICT" == "true" ]] && echo "$OUTPUT" | grep -qiE "no release type found|There are no relevant changes"; then
  summary_strict_mode  
fi

# ------------------------------------------------------------
# Robust version extraction
# ------------------------------------------------------------
VERSION=$(echo "$OUTPUT" \
  | grep -Eo 'next release version is ([0-9]+\.[0-9]+\.[0-9]+)' \
  | sed -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+)/\1/' \
  | head -n1 || true)

if [[ -z "$VERSION" ]]; then
  log "ℹ️ No next release version detected"
  exit 0
fi
log "✅ Next release version detected: ${VERSION:-<none>}"
echo "$VERSION"
