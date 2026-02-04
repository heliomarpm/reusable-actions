#!/usr/bin/env bash
set -e

echo "🚀 Running Node.js release"

# npm install -g semantic-release \
#   @semantic-release/changelog \
#   @semantic-release/git \
#   @semantic-release/github \
#   @semantic-release/npm

# CONFIG_MODE=$(./scripts/release/detect-release-consumer.sh)

# if [ "$CONFIG_MODE" = "custom" ]; then
#   echo "✅ Using consumer semantic-release config"
#   semantic-release
# else
#   echo "⚠️ Using default Node.js release config"
#   semantic-release --extends ./scripts/release/node/releaserc.json
# fi


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() {
  echo "▶ $1"
}
has_file() {
  [[ -f "$1" ]]
}

# ------------------------------------------------------------
# Detect semantic-release config
# ------------------------------------------------------------
CUSTOM_CONFIG=$(../detect-release-consumer.sh)

# ----------------------------------------------------------
# Install dependencies ONLY if needed
# ----------------------------------------------------------
if [ "$CUSTOM_CONFIG" = "true" ]; then
  log "Installing project dependencies (required by custom config)"

  if has_file "pnpm-lock.yaml"; then
    log "Using pnpm"
    corepack enable
    pnpm install --frozen-lockfile
  elif has_file "yarn.lock"; then
    log "Using yarn"
    corepack enable
    yarn install --frozen-lockfile
  elif has_file "package-lock.json"; then
    log "Using npm (ci)"
    npm ci
  else
    log "Using npm"
    npm install
  fi
else
  log "Skipping dependency installation"
fi

# ----------------------------------------------------------
# Run semantic-release
# ----------------------------------------------------------
if [ "$CUSTOM_CONFIG" = "true" ]; then
  log "Running semantic-release with consumer config"
  npx semantic-release
else
  log "Running semantic-release with default config"
  npx semantic-release --extends releaserc.json
fi

exit 0