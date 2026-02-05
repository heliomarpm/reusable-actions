#!/usr/bin/env bash
# set -e

# MODE=$1 # CUSTOM | DEFAULT

# npm install --no-save semantic-release \
#   @semantic-release/commit-analyzer \
#   @semantic-release/release-notes-generator \
#   @semantic-release/changelog \
#   @semantic-release/git \
#   @semantic-release/github

# if [ "$MODE" = "CUSTOM" ]; then
#   echo "▶ Using consumer semantic-release config"
#   npx semantic-release
# else
#   echo "▶ Using reusable-actions default config"
#   npx semantic-release \
#     --extends ./scripts/release/default.releaserc.json
# fi

set -euo pipefail

echo "🚀 Starting release process"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

log() {
  echo "▶ $1"
}

has_file() {
  [[ -f "$1" ]]
}

# ------------------------------------------------------------
# Detect stack
# ------------------------------------------------------------
STACK=$(./scripts/detect-stack.sh)

echo "Detected stack: $STACK"

SCRIPT_DIR="$(dirname "$0")"

echo "-> Executing $STACK release script from $SCRIPT_DIR"

chmod +x "$SCRIPT_DIR/$STACK/release.sh"
"$SCRIPT_DIR/$STACK/release.sh"


# ------------------------------------------------------------
# Unsupported project
# ------------------------------------------------------------
# echo "❌ Unsupported project type"
# echo "Supported: Node.js (package.json) or PHP (composer.json)"
# exit 1



