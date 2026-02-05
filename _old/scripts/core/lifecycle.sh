#!/usr/bin/env bash

run_lifecycle() {
  log_section "Running Tests"
  plugin_test

  log_section "Running Coverage"
  plugin_coverage

  log_section "Running Release"
  plugin_release

  log_section "Running Publish"
  plugin_publish
}
