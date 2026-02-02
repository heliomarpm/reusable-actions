#!/usr/bin/env bash
set -e

echo "🚀 Running PHP release"

npm install -g semantic-release \
  @semantic-release/changelog \
  @semantic-release/git \
  @semantic-release/github \
  @semantic-release/exec

CONFIG_MODE=$(./scripts/release/detect-release-consumer.sh)

if [ "$CONFIG_MODE" = "custom" ]; then
  echo "✅ Using consumer semantic-release config"
  semantic-release
else
  echo "⚠️ Using default PHP release config"
  semantic-release --extends ./scripts/release/php/releaserc.json
fi
