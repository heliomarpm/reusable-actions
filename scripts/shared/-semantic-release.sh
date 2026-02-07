#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Running Node.js release"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
log() {
  echo "→ $1"
}

fail() {
  echo "❌ $1" >&2
  exit 1
}

has_file() {
  [[ -f "$1" ]]
}

render_markdown() {
  local file="$1"

  echo ""
  sed 's/^/│ /' "$file" >&2
  echo ""
}

# ------------------------------------------------------------
# Env
# ------------------------------------------------------------
REUSABLE_PATH="${REUSABLE_PATH:-.}"
STACK="${STACK:-node}"
IS_DRY_RUN="${SEMANTIC_RELEASE_DRY_RUN:-false}"
IS_DEBUG_MODE="${SEMANTIC_RELEASE_DEBUG_MODE:-false}"
STRICT_MODE="${STRICT_CONVENTIONAL_COMMITS:-false}"
CUSTOM_CONFIG_PATH="${SEMANTIC_RELEASE_CONFIG:-}"

DEFAULT_CONFIG="./$REUSABLE_PATH/scripts/plugins/$STACK/releaserc.json"
STRICT_TEMPLATE="$REUSABLE_PATH/scripts/templates/strict-mode-error.md"

# ------------------------------------------------------------
# Detect semantic-release config
# ------------------------------------------------------------
USE_CUSTOM_CONFIG=false

if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
  if [[ -f "$CUSTOM_CONFIG_PATH" ]]; then
    log "Using consumer config: $CUSTOM_CONFIG_PATH"
    USE_CUSTOM_CONFIG=true
  else
    fail "SEMANTIC_RELEASE_CONFIG was provided but not found: $CUSTOM_CONFIG_PATH"
  fi
else
  CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/detect-releaserc.sh" || true)

  if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
    log "Detected consumer config: $CUSTOM_CONFIG_PATH"
    USE_CUSTOM_CONFIG=true
  fi
fi

# ----------------------------------------------------------
# Install dependencies ONLY if needed
# ----------------------------------------------------------
INSTALL_TOOLCHAIN=false

if [[ "$USE_CUSTOM_CONFIG" == "true" ]]; then
  log "Installing project dependencies (required by custom config)"

  if has_file "pnpm-lock.yaml"; then
    corepack enable
    pnpm install --frozen-lockfile
  elif has_file "yarn.lock"; then
    corepack enable
    yarn install --frozen-lockfile
  elif has_file "package-lock.json"; then
    npm ci
  elif has_file "package.json"; then
    npm install
  else
    INSTALL_TOOLCHAIN=true
  fi
else
  INSTALL_TOOLCHAIN=true
fi

# ----------------------------------------------------------
# Build semantic-release command
# ----------------------------------------------------------
CMD="npx semantic-release"

if [[ "$USE_CUSTOM_CONFIG" == "true" ]]; then
  log "Running semantic-release with consumer config"
  CMD+=" --extends $CUSTOM_CONFIG_PATH"
else
  [[ -f "$DEFAULT_CONFIG" ]] || fail "Default config not found for stack: $STACK"
  log "Running semantic-release with default config"
  CMD+=" --extends $DEFAULT_CONFIG"
fi

if [[ "$IS_DRY_RUN" == "true" || "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  log "Dry-run enabled"
  CMD+=" --dry-run"
fi

if [[ "$IS_DEBUG_MODE" == "true" ]]; then
  log "Debug mode enabled"
  CMD+=" --debug"
fi

# ------------------------------------------------------------
# Install semantic-release toolchain (ONE SHOT)
# ------------------------------------------------------------
if [[ "$INSTALL_TOOLCHAIN" == "true" ]]; then
  log "Installing semantic-release toolchain"

  TOOLCHAIN=(
    semantic-release
    @semantic-release/commit-analyzer
    @semantic-release/release-notes-generator
    @semantic-release/changelog
    @semantic-release/npm
    @semantic-release/github
    @semantic-release/git
    @semantic-release/exec
  )

  npm install --no-save "${TOOLCHAIN[@]}"
fi

# ------------------------------------------------------------
# STRICT MODE — Enforce conventional commits
# ------------------------------------------------------------
if [[ "$STRICT_MODE" == "true" ]]; then
  log "Strict mode enabled — validating conventional commits"

  STRICT_CMD="$CMD --dry-run"
  OUTPUT=$(eval "$STRICT_CMD" 2>&1 || true)

  if echo "$OUTPUT" | grep -qiE "no release type found|There are no relevant changes"; then
    echo "❌ Release blocked by STRICT MODE" >&2

    if [[ -f "$STRICT_TEMPLATE" ]]; then
      render_markdown "$STRICT_TEMPLATE"
    else
      echo "See Conventional Commits specification: https://www.conventionalcommits.org" >&2
    fi

    exit 1
  fi

  log "Conventional commits validation passed"
fi

# ------------------------------------------------------------
# Run release
# ------------------------------------------------------------
log "🚀 Running: $CMD"
eval "$CMD"

log "🎉 Done."
