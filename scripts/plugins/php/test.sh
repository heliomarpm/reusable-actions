#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../shared/shell-helpers.sh"

echo "🧪 Running PHP tests..."

MARKER_FILE="${RUNNER_TEMP:-/tmp}/reusable_tests_skipped"
rm -f "$MARKER_FILE"

if [[ -f vendor/bin/phpunit ]]; then
  vendor/bin/phpunit
elif [[ -f vendor/bin/pest ]]; then
  vendor/bin/pest
else
  echo "⚠️ No test runner found (PHPUnit/Pest)"
  touch "$MARKER_FILE"
  exit 0
fi

echo "✅ PHP tests passed"
