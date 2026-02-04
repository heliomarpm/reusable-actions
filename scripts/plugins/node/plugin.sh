#!/usr/bin/env bash

plugin_detect() {
  [[ -f package.json ]]
}

plugin_install_deps() {
  ./scripts/plugins/node/install.sh
}

plugin_run_tests() {
  ./scripts/plugins/node/test.sh
}

plugin_run_coverage() {
  ./scripts/plugins/node/coverage.sh
}

plugin_release() {
  ./scripts/plugins/node/release.sh
}

plugin_publish() {
  ./scripts/plugins/node/publish.sh
}
