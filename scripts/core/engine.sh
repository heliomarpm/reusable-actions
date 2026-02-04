#!/usr/bin/env bash
set -e

run_engine() {

  STACK="$1"

  load_plugin "$STACK"

  echo "🚀 Running lifecycle for $STACK"

  plugin_install_deps || true
  plugin_run_tests || true
  plugin_run_coverage || true
  plugin_release
  plugin_publish || true
}
