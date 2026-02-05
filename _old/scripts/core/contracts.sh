# plugin_detect() { :; }
# plugin_install_deps() { :; }
# plugin_run_tests() { :; }
# plugin_run_coverage() { :; }
# plugin_release() { :; }
# plugin_publish() { :; }

#!/usr/bin/env bash

validate_plugin_contract() {

  local required=(
    plugin_detect
    plugin_test
    plugin_coverage
    plugin_release
    plugin_publish
  )

  for fn in "${required[@]}"; do
    if ! declare -f "$fn" > /dev/null; then
      log_error "Plugin missing required function: $fn"
      exit 1
    fi
  done
}

