plugin_detect() { :; }
plugin_install_deps() { :; }
plugin_run_tests() { :; }
plugin_run_coverage() { :; }
plugin_release() { :; }
plugin_publish() { :; }

validate_plugin_contract() {

  REQUIRED=("plugin_release")

  for fn in "${REQUIRED[@]}"; do
    if ! declare -f "$fn" >/dev/null; then
      echo "❌ Plugin missing required function: $fn"
      exit 1
    fi
  done
}
