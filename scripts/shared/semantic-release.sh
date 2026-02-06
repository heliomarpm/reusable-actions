#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Running Node.js release"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() {
  echo "🔹 $1"
}
has_file() {
  [[ -f "$1" ]]
}

REUSABLE_PATH="${REUSABLE_PATH:-.}"
STACK="${STACK:-node}"
IS_DRY_RUN=${SEMANTIC_RELEASE_DRY_RUN:-false} || [ "$GITHUB_EVENT_NAME" == "pull_request" ]
IS_DEBUG_MODE=${SEMANTIC_RELEASE_DEBUG_MODE:-false}

# ------------------------------------------------------------
# Detect semantic-release config
# ------------------------------------------------------------
CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/detect-releaserc.sh")

if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
  log "Using consumer config: $CUSTOM_CONFIG_PATH"
  USE_CUSTOM_CONFIG=true
else
  USE_CUSTOM_CONFIG=false
fi

# ----------------------------------------------------------
# Install dependencies ONLY if needed
# ----------------------------------------------------------
INSTALL_SEMANTIC_RELEASE=fakse
DEFAULT_CONFIG="./$REUSABLE_PATH/scripts/plugins/$STACK/releaserc.json"

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
    INSTALL_SEMANTIC_RELEASE=true
  fi
else
  log "Skipping dependency installation"
  INSTALL_SEMANTIC_RELEASE=true
fi

# ----------------------------------------------------------
# Run semantic-release
# ----------------------------------------------------------
CMD="npx semantic-release"

if [ "$USE_CUSTOM_CONFIG" = "false" ]; then
  if [ ! -f "$DEFAULT_CONFIG" ]; then    
    echo "❌ Release script not found for stack: $STACK"
    exit 1
  fi

  log "Running semantic-release with default config"
  CMD+=" --extends $DEFAULT_CONFIG"
else
  log "Running semantic-release with consumer config"
  CMD+=" --extends $CUSTOM_CONFIG"
fi

if [[ "$IS_DRY_RUN" == "true" ]]; then
  log "PR detected → dry-run"
  CMD="$CMD --dry-run"
fi

if [[ "$IS_DEBUG_MODE" == "true" ]]; then
  log "Debug mode enabled"
  CMD="$CMD --debug"
fi

if INSTALL_SEMANTIC_RELEASE; then
  log "Installing semantic-release core"
  npm install --no-save semantic-release

  if [ -f "$DEFAULT_CONFIG" ]; then
    # ------------------------------------------------------------
    # Detect plugins from config (JSON only for now)
    # ------------------------------------------------------------
    if [[ "$DEFAULT_CONFIG" == *.json ]]; then
      PLUGINS=$(jq -r '.plugins[]? | if type=="string" then . else .[0] end' "$DEFAULT_CONFIG")
    else
      echo "⚠️ Non-JSON config detected, installing default plugin set"
      PLUGINS="
        @semantic-release/commit-analyzer
        @semantic-release/release-notes-generator
        @semantic-release/changelog
        @semantic-release/github
        @semantic-release/git
        @semantic-release/exec
        @semantic-release/npm
      "
    fi

    # ------------------------------------------------------------
    # Install plugins
    # ------------------------------------------------------------
    for plugin in $PLUGINS; do
      echo "📦 Installing $plugin"
      npm install --no-save "$plugin"
    done
  fi
fi

log "🚀 Running: $CMD"
log "🎉 Done."
eval "$CMD"