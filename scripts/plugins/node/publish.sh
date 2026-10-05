#!/usr/bin/env bash
set -euo pipefail

echo "📦 Node publish step"

# Resolve versão
VERSION="${NEXT_VERSION:-${INPUT_VERSION:-}}"
if [[ -z "$VERSION" ]]; then
  if [[ -f package.json ]]; then
    VERSION=$(node -p "try { require('./package.json').version } catch(e) { '' }" 2>/dev/null || echo "")
  fi
fi

if [[ -z "$VERSION" || "$VERSION" == "0.0.0" ]]; then
  VERSION="${GITHUB_REF_NAME:-}"
fi

# Se versão for passada (ex: v1.2.3), sincroniza no package.json sem criar git tag
if [[ -n "$VERSION" && -f package.json ]]; then
  CLEAN_VERSION="${VERSION#v}"
  echo "📝 Syncing version $CLEAN_VERSION into package.json"
  npm version "$CLEAN_VERSION" --no-git-tag-version --allow-same-version 2>/dev/null || true
fi

echo "🚀 Publishing version: ${VERSION:-<from package.json>}"

DRY_RUN_FLAG=""
if [[ "${DRY_RUN:-false}" == "true" ]]; then
  echo "🧪 Dry-run enabled — simulating publish"
  DRY_RUN_FLAG="--dry-run"
fi

EXTRA_FLAGS=()
if [[ -n "$DRY_RUN_FLAG" ]]; then
  EXTRA_FLAGS+=("$DRY_RUN_FLAG")
fi

RESTORE_NAME=false
cleanup() {
  if [[ "$RESTORE_NAME" == "true" && -f package.json.orig_scope ]]; then
    mv package.json.orig_scope package.json
  fi
}
trap cleanup EXIT

REG="${REGISTRY:-}"
if [[ "$REG" == "github" || "$REG" == "gh" ]]; then
  EXTRA_FLAGS+=(--registry=https://npm.pkg.github.com)
  if [[ -f package.json ]]; then
    PKG_NAME=$(node -p "try { require('./package.json').name } catch(e) { '' }" 2>/dev/null || echo "")
    if [[ -n "$PKG_NAME" && "$PKG_NAME" != @* ]]; then
      OWNER="${GITHUB_REPOSITORY_OWNER:-}"
      if [[ -z "$OWNER" && -n "${GITHUB_REPOSITORY:-}" ]]; then
        OWNER="${GITHUB_REPOSITORY%%/*}"
      fi
      if [[ -n "$OWNER" ]]; then
        SCOPED_NAME="@${OWNER,,}/$PKG_NAME"
        echo "⚠️ Package name '$PKG_NAME' is unscoped. GitHub Packages requires a scope matching repository owner."
        echo "🔄 Temporarily scoping package name to '$SCOPED_NAME' for GitHub Packages"
        cp package.json package.json.orig_scope
        RESTORE_NAME=true
        node -e "const fs = require('fs'); const p = JSON.parse(fs.readFileSync('package.json', 'utf8')); p.name = '$SCOPED_NAME'; fs.writeFileSync('package.json', JSON.stringify(p, null, 2));" 2>/dev/null || true
      fi
    fi
  fi
elif [[ "$REG" == "npm" || "$REG" == "npmjs" ]]; then
  EXTRA_FLAGS+=(--registry=https://registry.npmjs.org)
fi

if [[ -f pnpm-lock.yaml ]]; then
  pnpm publish --no-git-checks "${EXTRA_FLAGS[@]}"
elif [[ -f yarn.lock ]]; then
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "ℹ️ Yarn dry-run simulation completed"
  else
    yarn publish ${VERSION:+--new-version "${VERSION#v}"} --non-interactive
  fi
else
  npm publish "${EXTRA_FLAGS[@]}"
fi

echo "✅ Node publish completed"
