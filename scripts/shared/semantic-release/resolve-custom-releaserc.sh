#!/usr/bin/env bash
set -euo pipefail

log() { echo "→ $1"; }
has_file() { [[ -f "$1" ]]; }

fail() {
  echo "::error::$1"
  exit 1
}

detect_config() {
  echo "🔎 Detecting custom semantic-release config"
  
  local CUSTOM_CONFIG_PATH="${1:-}"

  if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
    if [[ -f "$CUSTOM_CONFIG_PATH" ]]; then
      log "Using consumer config: $CUSTOM_CONFIG_PATH"
    else
      fail "SEMANTIC_RELEASE_CONFIG was provided but not found: $CUSTOM_CONFIG_PATH"
    fi
  else
    CUSTOM_CONFIG_PATH=$(bash "$REUSABLE_PATH/scripts/shared/detect-releaserc.sh" || true)

    if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then
      log "Detected consumer config: $CUSTOM_CONFIG_PATH"
    fi
  fi

  if [[ -n "$CUSTOM_CONFIG_PATH" ]]; then 
    # Normaliza para sempre começar com "./" 
    CUSTOM_CONFIG_PATH="${CUSTOM_CONFIG_PATH#./}" 
    CUSTOM_CONFIG_PATH="./$CUSTOM_CONFIG_PATH" 

    echo "$CUSTOM_CONFIG_PATH"
  else
    echo ""
  fi
}

echo $(detect_config "$1")