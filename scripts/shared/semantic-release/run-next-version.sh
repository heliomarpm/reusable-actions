#!/usr/bin/env bash
set -euo pipefail

# echo "🚀 Semantic Release Next Version Script"

REUSABLE_PATH="${REUSABLE_PATH:?}"
STRICT="${STRICT_CONVENTIONAL_COMMITS:-false}"

CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/semantic-release/resolve-custom-releaserc.sh" "${SEMANTIC_RELEASE_CONFIG:-}")
STRICT_TEMPLATE="$REUSABLE_PATH/templates/strict-mode-error.md"

# npm install --no-save semantic-release @semantic-release/commit-analyzer
bash "$REUSABLE_PATH/scripts/shared/semantic-release/install.sh"

# ------------------------------------------------------------
# STRICT MODE — Enforce conventional commits
# ------------------------------------------------------------
summary_string_mode() {
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
}

CMD="npx semantic-release --dry-run"
[[ -n "$CUSTOM_CONFIG_PATH" ]] && CMD+=" --extends $CUSTOM_CONFIG_PATH"

OUTPUT=$(eval "$CMD" 2>&1 || true)

if [[ "$STRICT" == "true" ]] && echo "$OUTPUT" | grep -qi "no release type found"; then
  summary_string_mode
fi

echo "$OUTPUT" | grep -oE 'next release version is ([0-9]+\.[0-9]+\.[0-9]+)' | awk '{print $5}'
