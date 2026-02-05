#!/usr/bin/env bash
set -euo pipefail

source "$REUSABLE_PATH/scripts/core/logger.sh"
source "$REUSABLE_PATH/scripts/core/contracts.sh"
source "$REUSABLE_PATH/scripts/core/plugin-loader.sh"
source "$REUSABLE_PATH/scripts/core/lifecycle.sh"

STACK="$1"

log_section "🚀 Running lifecycle for $STACK"
# log_section "Initializing Engine"

load_plugin "$STACK"

run_lifecycle

log_success "Pipeline completed"
