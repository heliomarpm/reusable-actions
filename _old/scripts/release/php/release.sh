#!/usr/bin/env bash

# npm install -g semantic-release \
#   @semantic-release/changelog \
#   @semantic-release/git \
#   @semantic-release/github \
#   @semantic-release/exec

# CONFIG_MODE=$(./scripts/release/detect-release-consumer.sh)

# if [ "$CONFIG_MODE" = "custom" ]; then
#   echo "✅ Using consumer semantic-release config"
#   semantic-release
# else
#   echo "⚠️ Using default PHP release config"
#   semantic-release --extends ./scripts/release/php/releaserc.json
# fi

set -e

echo "🚀 Running PHP release"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() {
  echo "▶ $1"
}

# ------------------------------------------------------------
# Detect semantic-release config
# ------------------------------------------------------------
CUSTOM_CONFIG=$(../detect-release-consumer.sh)

if [ "$CUSTOM_CONFIG" = "true" ]; then
  log "Using consumer release config"
  npx semantic-release
else
  log "Using default PHP release config"
  npx semantic-release --extends releaserc.json
fi

exit 0