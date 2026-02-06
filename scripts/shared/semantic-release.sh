#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Running Node.js release"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() {
  echo "→ $1"
}
has_file() {
  [[ -f "$1" ]]
}

REUSABLE_PATH="${REUSABLE_PATH:-.}"
STACK="${STACK:-node}"
IS_DRY_RUN="${SEMANTIC_RELEASE_DRY_RUN:-false}"
IS_DEBUG_MODE="${SEMANTIC_RELEASE_DEBUG_MODE:-false}"
CUSTOM_CONFIG_PATH="${SEMANTIC_RELEASE_CONFIG:-}"

DEFAULT_CONFIG="./$REUSABLE_PATH/scripts/plugins/$STACK/releaserc.json"

# ------------------------------------------------------------
# Detect semantic-release config
# ------------------------------------------------------------
USE_CUSTOM_CONFIG=false

if [[ -n "$CUSTOM_CONFIG_PATH" && -f "$CUSTOM_CONFIG_PATH" ]]; then
  log "Using consumer config: $CUSTOM_CONFIG_PATH"
  USE_CUSTOM_CONFIG=true
else
  CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/detect-releaserc.sh" || true)
  if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
    log "Detected consumer config: $CUSTOM_CONFIG_PATH"
    USE_CUSTOM_CONFIG=true
  fi
fi

# ----------------------------------------------------------
# Install dependencies ONLY if needed
# ----------------------------------------------------------
INSTALL_TOOLCHAIN=false

if [ "$USE_CUSTOM_CONFIG" = "true" ]; then
  log "Installing project dependencies (required by custom config)"

  if has_file "pnpm-lock.yaml"; then
    log "Installing with pnpm"
    corepack enable
    pnpm install --frozen-lockfile
  elif has_file "yarn.lock"; then
    log "Installing with yarn"
    corepack enable
    yarn install --frozen-lockfile
  elif has_file "package-lock.json"; then
    log "Installing with npm (ci)"
    npm ci
  elif has_file "package.json"; then
    log "Installing with npm"
    npm install
  else 
    log "Skipping custom config installation"
    INSTALL_TOOLCHAIN=true
  fi
else
  INSTALL_TOOLCHAIN=true
fi

# ----------------------------------------------------------
# Run semantic-release
# ----------------------------------------------------------
CMD="npx semantic-release"

if [[ "$USE_CUSTOM_CONFIG" == "true" ]]; then
  log "Running semantic-release with consumer config"
  CMD+=" --extends $CUSTOM_CONFIG_PATH"
else
  [[ -f "$DEFAULT_CONFIG" ]] || { echo "❌ Default config not found for stack: $STACK"; exit 1; }

  log "Running semantic-release with default config"
  CMD+=" --extends $DEFAULT_CONFIG"
fi

if [[ "$IS_DRY_RUN" == "true" || "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  log "Dry-run enabled"
  CMD+=" --dry-run"
fi

if [[ "$IS_DEBUG_MODE" == "true" ]]; then
  log "Debug mode enabled"
  CMD+=" --debug"
fi

# ------------------------------------------------------------
# Install semantic-release toolchain (ONE SHOT)
# ------------------------------------------------------------
if [[ "$INSTALL_TOOLCHAIN" == "true" ]]; then
  # log "Installing semantic-release core"
  # npm install --no-save semantic-release

  # if [ -f "$DEFAULT_CONFIG" ]; then
  #   # ------------------------------------------------------------
  #   # Detect plugins from config (JSON only for now)
  #   # ------------------------------------------------------------
  #   if [[ "$DEFAULT_CONFIG" == *.json ]]; then
  #     PLUGINS=$(jq -r '.plugins[]? | if type=="string" then . else .[0] end' "$DEFAULT_CONFIG")
  #   else
  #     echo "⚠️ Non-JSON config detected, installing default plugin set"
  #     PLUGINS="
  #       @semantic-release/commit-analyzer
  #       @semantic-release/release-notes-generator
  #       @semantic-release/changelog
  #       @semantic-release/github
  #       @semantic-release/git
  #       @semantic-release/exec
  #       @semantic-release/npm
  #     "
  #   fi

  #   for plugin in $PLUGINS; do
  #     echo "📦 Installing $plugin"
  #     npm install --no-save "$plugin"
  #   done
  # fi

  log "Installing semantic-release toolchain"

  TOOLCHAIN=(
    semantic-release
    @semantic-release/commit-analyzer
    @semantic-release/release-notes-generator
    @semantic-release/changelog
    @semantic-release/npm
    @semantic-release/github
    @semantic-release/git
    @semantic-release/exec
  )

  npm install --no-save "${TOOLCHAIN[@]}"
fi

log "🚀 Running: $CMD"
eval "$CMD"

log "🎉 Done."
