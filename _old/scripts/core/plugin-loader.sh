#!/usr/bin/env bash

load_plugin() {

  local STACK="$1"
  local PLUGIN_PATH="$REUSABLE_PATH/scripts/plugins/$STACK/plugin.sh"

  if [[ ! -f "$PLUGIN_PATH" ]]; then
    echo "❌ Plugin not found for stack: $STACK"
    exit 1
  fi

  source "$PLUGIN_PATH"

  validate_plugin_contract
}
