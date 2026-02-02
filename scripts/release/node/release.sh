#!/usr/bin/env bash
set -e

echo "🚀 Running Node.js release"

npm install -g semantic-release \
  @semantic-release/changelog \
  @semantic-release/git \
  @semantic-release/github \
  @semantic-release/npm

CONFIG_MODE=$(./scripts/release/detect-release-consumer.sh)

if [ "$CONFIG_MODE" = "custom" ]; then
  echo "✅ Using consumer semantic-release config"
  semantic-release
else
  echo "⚠️ Using default Node.js release config"
  semantic-release --extends ./scripts/release/node/releaserc.json
fi
