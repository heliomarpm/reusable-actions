#!/usr/bin/env bash
set -e

echo "🚀 Running Node.js release"

npm install -g semantic-release \
  @semantic-release/changelog \
  @semantic-release/git \
  @semantic-release/github \
  @semantic-release/npm

CONFIG_MODE=$(./scripts/release/detect-release-config.sh)

if [ "$CONFIG_MODE" = "custom" ]; then
  echo "✅ Using consumer semantic-release config"
  semantic-release
else
  echo "⚠️ Using default Node.js release config"
  semantic-release --extends ./scripts/release/default/node.releaserc.json
fi


# #!/usr/bin/env bash
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
