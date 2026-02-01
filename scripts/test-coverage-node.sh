#!/bin/sh
set -e

echo "▶ Running Node.js coverage detection"

mkdir -p coverage

########################################
# 1️⃣ Detect Vitest
########################################
if npx --yes vitest --version >/dev/null 2>&1; then
  echo "🧪 Detected Vitest"

  npx vitest run --coverage

  RAW_FILE="coverage/coverage-summary.json"

  if [ ! -f "$RAW_FILE" ]; then
    echo "❌ Vitest did not generate coverage-summary.json"
    exit 1
  fi

  LINE=$(jq '.total.lines.pct' "$RAW_FILE")

########################################
# 2️⃣ Detect Jest
########################################
elif npx --yes jest --version >/dev/null 2>&1; then
  echo "🧪 Detected Jest"

  npx jest --coverage --coverageReporters=json-summary

  RAW_FILE="coverage/coverage-summary.json"

  if [ ! -f "$RAW_FILE" ]; then
    echo "❌ Jest did not generate coverage-summary.json"
    exit 1
  fi

  LINE=$(jq '.total.lines.pct' "$RAW_FILE")

########################################
# 3️⃣ No coverage tool detected
########################################
else
  echo "⚠️ No supported Node.js coverage tool detected (Vitest/Jest)"
  echo "Generating empty coverage report"

  cat <<EOF > coverage/coverage-summary.normalized.json
{
  "line": 0,
  "branch": 0,
  "function": 0
}
EOF

  exit 0
fi

########################################
# 4️⃣ Normalize output (contract)
########################################
cat <<EOF > coverage/coverage-summary.normalized.json
{
  "line": $LINE,
  "branch": $LINE,
  "function": $LINE
}
EOF

echo "✅ Node.js coverage normalized: $LINE%"
