#!/usr/bin/env bash
set -e

echo "🐹 Running Go release"

CUSTOM_CONFIG=$(../detect-releaserc-consumer.sh)

if [ "$CUSTOM_CONFIG" = "true" ]; then
  npx semantic-release
else
  npx semantic-release --extends releaserc.json
fi
