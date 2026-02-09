# No scripts/plugins/node/releaserc.json, adicionamos @semantic-release/exec:
# Adicione o seguinte script:
# [
#   "@semantic-release/exec",
#   {
#     "publishCmd": "bash scripts/plugins/node/publish.sh"
#   }
# ]

#!/usr/bin/env bash
set -euo pipefail

echo "📦 Node publish step"

if [[ -z "${NEXT_VERSION:-}" ]]; then
  echo "ℹ️ No release detected. Skipping publish."
  exit 0
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
  echo "🧪 Dry-run enabled — publish skipped"
  exit 0
fi

echo "🚀 Publishing version: $NEXT_VERSION"

if [[ -f pnpm-lock.yaml ]]; then
  pnpm publish --no-git-checks
elif [[ -f yarn.lock ]]; then
  yarn publish --new-version "$NEXT_VERSION"
else
  npm publish
fi

echo "✅ Publish completed"
