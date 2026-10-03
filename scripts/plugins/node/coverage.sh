#!/bin/bash 
set -euo pipefail

echo "🚀 Running Node.js coverage detection"

RAW_FILE=null

if [ -x "node_modules/.bin/vitest" ]; then
  echo "🧪 Detected Vitest (local)"
  # Evita que o Vitest duplique o relatório de testes no Job Summary durante a etapa de cobertura
  GITHUB_STEP_SUMMARY=/dev/null npx vitest run --coverage
  RAW_FILE="coverage/coverage-summary.json"

elif [ -x "node_modules/.bin/jest" ]; then
  echo "🧪 Detected Jest (local)"
  GITHUB_STEP_SUMMARY=/dev/null npx jest --coverage --coverageReporters=json-summary
  RAW_FILE="coverage/coverage-summary.json"

else
  echo "⚠️ Tests detected, but no supported runner found (Vitest/Jest)."
  exit 0
fi

# ------------------------------------------------------------
# Validação do output de cobertura
# ------------------------------------------------------------
if [ ! -f "$RAW_FILE" ]; then
  echo "❌ Coverage tool did not generate coverage-summary.json"
  exit 1
fi

LINE=$(jq '.total.lines.pct' "$RAW_FILE")

# ------------------------------------------------------------
# Normalização para o contrato padrão
# ------------------------------------------------------------
mkdir -p coverage
cat <<EOF > coverage/coverage-summary.normalized.json
{
  "line": $LINE,
  "branch": $LINE,
  "function": $LINE
}
EOF

echo "✅ Node.js coverage normalized: $LINE%"
