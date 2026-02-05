#!/usr/bin/env bash
set -e

log() {
  echo "▶ $1"
}

for file in \
  .releaserc \
  .releaserc.json \
  .releaserc.yml \
  .releaserc.yaml \
  release.config.js
do
  if [ -f "$file" ]; then
    log "Custom semantic-release config detected: $file"
    echo "true"
    exit 0
  fi
done

echo "false"
