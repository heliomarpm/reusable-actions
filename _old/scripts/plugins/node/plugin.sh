#!/usr/bin/env bash

source "$REUSABLE_PATH/scripts/core/logger.sh"

plugin_detect() {
  [[ -f package.json ]]
}

plugin_test() {
  npm install
  npm test
}

plugin_coverage() {
  npm run coverage || log_warn "Coverage not configured"
}

plugin_release() {
  bash "$REUSABLE_PATH/scripts/plugins/node/release/release.sh"
}

plugin_publish() {
  log "Node publish handled by semantic-release"
}


# plugin_install_deps() {
#   ./scripts/plugins/node/install.sh
# }

# plugin_run_tests() {
#   ./scripts/plugins/node/test.sh
# }

# plugin_run_coverage() {
#   ./scripts/plugins/node/coverage.sh
# }

# plugin_release() {
#   ./scripts/plugins/node/release.sh
# }

# plugin_publish() {
#   ./scripts/plugins/node/publish.sh
# }
