#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../shared/shell-helpers.sh"

echo "🧪 Running PHP tests..."

if [[ -f vendor/bin/phpunit ]]; then
  vendor/bin/phpunit
elif [[ -f vendor/bin/pest ]]; then
  vendor/bin/pest
else
  echo "⚠️ No test runner found (PHPUnit/Pest)"
  exit 2
fi

echo "✅ PHP tests passed"
