#!/usr/bin/env bash
set -e

for file in \
  .releaserc \
  .releaserc.json \
  .releaserc.yml \
  .releaserc.yaml \
  release.config.js
do
  if [ -f "$file" ]; then
    echo "CUSTOM"
    exit 0
  fi
done

echo "DEFAULT"
