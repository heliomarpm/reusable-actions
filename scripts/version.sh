#!/usr/bin/env bash
set -e

CURRENT=$1
COMMITS=$2

MAJOR=0
MINOR=0
PATCH=0

IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT#v}"

if echo "$COMMITS" | grep -q "BREAKING CHANGE"; then
  ((MAJOR++))
  MINOR=0
  PATCH=0
elif echo "$COMMITS" | grep -q "^feat"; then
  ((MINOR++))
  PATCH=0
elif echo "$COMMITS" | grep -qE "^fix|^perf"; then
  ((PATCH++))
else
  echo "ℹ️ No release-worthy commits found"
  exit 0
fi

echo "v$MAJOR.$MINOR.$PATCH"
