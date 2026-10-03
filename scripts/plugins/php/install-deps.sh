#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../shared/shell-helpers.sh"

echo "📦 Installing PHP dependencies..."

if [[ ! -f "composer.json" ]]; then
  echo "ℹ️ No composer.json found. Assuming legacy PHP project. Skipping dependency installation."
  exit 0
fi

if [[ -f composer.lock ]]; then
  composer install --no-interaction --prefer-dist --no-progress
else
  composer install --no-interaction --prefer-dist
fi

echo "✅ Dependencies installed"
