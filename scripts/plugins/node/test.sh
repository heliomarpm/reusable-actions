#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../shared/shell-helpers.sh"

echo "🧪 Running unit tests..."

MARKER_FILE="${RUNNER_TEMP:-/tmp}/reusable_tests_skipped"
rm -f "$MARKER_FILE"

if [[ ! -f package.json ]]; then
  echo "⚠️ No package.json found"
  touch "$MARKER_FILE"
  exit 0
fi

TEST_SCRIPT=$(jq -r '.scripts.test // empty' package.json 2>/dev/null || echo "")

if [[ -z "$TEST_SCRIPT" || "$TEST_SCRIPT" == *"no test specified"* ]]; then
  echo "⚠️ No test script configured in package.json"
  touch "$MARKER_FILE"
  exit 0
fi

npm test

echo "✅ Node.js tests passed"
