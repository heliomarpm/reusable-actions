#!/usr/bin/env bash
set -e

VERSION=$1
COMMITS=$2
DATE=$(date +"%Y-%m-%d")

{
  echo "## $VERSION - $DATE"
  echo
  echo "### Features"
  echo "$COMMITS" | grep "^feat" || true
  echo
  echo "### Fixes"
  echo "$COMMITS" | grep -E "^fix|^perf" || true
  echo
} > /tmp/CHANGELOG.tmp

if [ -f CHANGELOG.md ]; then
  cat CHANGELOG.md >> /tmp/CHANGELOG.tmp
fi

mv /tmp/CHANGELOG.tmp CHANGELOG.md
