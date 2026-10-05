#!/usr/bin/env bash
set -euo pipefail

echo "📦 PHP / Composer publish step"

if [[ -f composer.json ]]; then
  echo "🔍 Validating composer.json"
  composer validate --strict --no-check-all || true
fi

REG="${REGISTRY:-github}"
echo "🚀 Publishing for registry: $REG"

if [[ "$REG" == "packagist" ]]; then
  if [[ -n "${PACKAGIST_TOKEN:-${PUBLISH_TOKEN:-}}" && -n "${PACKAGIST_USER:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
    REPO_URL="https://github.com/${GITHUB_REPOSITORY}"
    echo "📡 Notifying Packagist for $REPO_URL"
    curl -s -XPOST -H'content-type:application/json' \
      "https://packagist.org/api/update-package?username=${PACKAGIST_USER}&apiToken=${PACKAGIST_TOKEN:-$PUBLISH_TOKEN}" \
      -d"{\"repository\":{\"url\":\"$REPO_URL\"}}" || echo "⚠️ Failed to notify Packagist"
  else
    echo "ℹ️ Packagist update skipped (requires PACKAGIST_USER and PACKAGIST_TOKEN)"
  fi
else
  echo "✅ PHP release tag is available for Composer / GitHub Packages"
fi

echo "✅ PHP publish completed"
