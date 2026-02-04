#!/usr/bin/env bash
set -e

echo "🐍 Running Python release"

CUSTOM_CONFIG=$(../detect-releaserc-consumer.sh)

if [ "$CUSTOM_CONFIG" = "true" ]; then
  echo "Using consumer config"
  npx semantic-release
else
  echo "Using default config"
  npx semantic-release --extends releaserc.json
fi
