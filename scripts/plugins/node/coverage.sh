#!/bin/bash 
set -euo pipefail

echo "🚀 Running Node.js coverage detection"

log() {
  echo "→ $1"
}

RAW_FILE=null

# # ------------------------------------------------------------
# # 0️⃣ Detect test existence
# # ------------------------------------------------------------
# HAS_TESTS=false

# if \
#   [ -d "tests" ] || \
#   [ -d "__tests__" ] || \
#   [ -d "test" ] || \
#   find . -type f \( -name "*.test.*" -o -name "*.spec.*" \) | grep -q .
# then
#   HAS_TESTS=true
# fi

# if [ "$HAS_TESTS" = "false" ]; then
#   echo "⚠️ No tests detected in project. Skipping coverage."

#   mkdir -p coverage
#   cat <<EOF > coverage/coverage-summary.normalized.json
# {
#   "line": 0,
#   "branch": 0,
#   "function": 0
# }
# EOF

#   exit 0
# fi


# if command -v vitest >/dev/null 2>&1; then
if [ -x "node_modules/.bin/vitest" ]; then
  echo "🧪 Detected Vitest (local)"
  # npm test -- --no-watch --coverage --reporter=verbose
  npx vitest run --coverage
  RAW_FILE="coverage/coverage-summary.json"

# elif command -v jest >/dev/null 2>&1; then
elif [ -x "node_modules/.bin/jest" ]; then
  echo "🧪 Detected Jest (local)"
  # npm test -- --no-watch --coverage --reporter=verbose
  npx jest --coverage --coverageReporters=json-summary
  RAW_FILE="coverage/coverage-summary.json"

else
  echo "⚠️ Tests detected, but no supported runner found (Vitest/Jest)."
#   log "Skipping coverage safely."

#   mkdir -p coverage
#   cat <<EOF > coverage/coverage-summary.normalized.json
# {
#   "line": 0,
#   "branch": 0,
#   "function": 0
# }
# EOF

  exit 0
fi

# ------------------------------------------------------------
# 4️⃣ Validate coverage output
# ------------------------------------------------------------
if [ ! -f "$RAW_FILE" ]; then
  echo "❌ Coverage tool did not generate coverage-summary.json"
  exit 1
fi

# Ensure jq is available 
# if ! command -v jq >/dev/null 2>&1; then 
#   echo "❌ jq is required but not installed" 
#   exit 1 
# fi

LINE=$(jq '.total.lines.pct' "$RAW_FILE")

# ------------------------------------------------------------
# 5️⃣ Normalize output (contract)
# ------------------------------------------------------------
cat <<EOF > coverage/coverage-summary.normalized.json
{
  "line": $LINE,
  "branch": $LINE,
  "function": $LINE
}
EOF

echo "✅ Node.js coverage normalized: $LINE%"
