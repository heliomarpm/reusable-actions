#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shell-helpers.sh"

log "🔎 Detecting custom semantic-release config"

CUSTOM_CONFIG="${1:-${SEMANTIC_RELEASE_CONFIG:-}}"

if [[ -n "$CUSTOM_CONFIG" ]]; then
  if [[ -f "$CUSTOM_CONFIG" ]]; then
    log "Using consumer config: $CUSTOM_CONFIG"
    if [[ "$CUSTOM_CONFIG" != /* && "$CUSTOM_CONFIG" != ./* ]]; then
      CUSTOM_CONFIG="./$CUSTOM_CONFIG"
    fi
    echo "$CUSTOM_CONFIG"
    exit 0
  else
    fail "SEMANTIC_RELEASE_CONFIG was provided but not found: $CUSTOM_CONFIG"
  fi
fi

DETECT_SCRIPT="$SCRIPT_DIR/../detect-releaserc.sh"
if [[ -f "$DETECT_SCRIPT" ]]; then
  DETECTED=$(bash "$DETECT_SCRIPT" || true)
  DETECTED="$(echo "$DETECTED" | tr -d '[:space:]')"
  if [[ -n "$DETECTED" && -f "$DETECTED" ]]; then
    log "Detected consumer config: $DETECTED"
    if [[ "$DETECTED" != /* && "$DETECTED" != ./* ]]; then
      DETECTED="./$DETECTED"
    fi
    echo "$DETECTED"
    exit 0
  fi
fi

# Nenhum config customizado encontrado
exit 0