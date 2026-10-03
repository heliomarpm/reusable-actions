#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../shared/shell-helpers.sh"

echo "🧪 Running unit tests..."

if [[ ! -f package.json ]]; then
  echo "⚠️ No package.json found"
  exit 2
fi

TEST_SCRIPT=$(jq -r '.scripts.test // empty' package.json 2>/dev/null || echo "")

# Verifica se o script de teste não existe ou é o placeholder padrão do npm
if [[ -z "$TEST_SCRIPT" || "$TEST_SCRIPT" == *"no test specified"* ]]; then
  echo "⚠️ No test script configured in package.json"
  exit 2
fi

npm test

echo "✅ Node.js tests passed"
