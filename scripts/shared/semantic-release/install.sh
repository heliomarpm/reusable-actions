#!/usr/bin/env bash
set -euo pipefail

log() { echo "→ $1"; }
has_file() { [[ -f "$1" ]]; }


install_toolchain() {  
  log "Installing semantic-release toolchain"

  TOOLCHAIN=(
    semantic-release
    @semantic-release/commit-analyzer
    @semantic-release/release-notes-generator
    @semantic-release/changelog
    @semantic-release/npm
    @semantic-release/github
    @semantic-release/git
    @semantic-release/exec
  )

  log "Installing: ${TOOLCHAIN[*]}"
  npm install --no-save "${TOOLCHAIN[@]}"
  
  echo "✅ Toolchain installation completed"
}

install_project_deps() {  
  echo "📦 Installing dependencies..."  

  if has_file "pnpm-lock.yaml"; then
    corepack enable
    pnpm install --frozen-lockfile
  elif has_file "yarn.lock"; then
    corepack enable
    yarn install --frozen-lockfile
  elif has_file "package-lock.json"; then
    npm ci
  elif has_file "package.json"; then
    npm install
  else
    install_toolchain
  fi
}

install_project_deps() {

# main() {
#   local CUSTOM_CONFIG_PATH=$(detect_config "${1}")
#   local USE_CUSTOM_CONFIG=$(has_file "$CUSTOM_CONFIG_PATH")
  
#   install_dependencies "$USE_CUSTOM_CONFIG" 
  
#   if [[ "$USE_CUSTOM_CONFIG" == "true" ]]; then
#     echo "$CUSTOM_CONFIG_PATH"
#   else
#     echo ""
#   fi
# }

# REUSABLE_PATH="${1}"

# # Run main if script is executed directly
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#   if [[ $# -lt 1 ]]; then
#     echo "Usage: $0 <reusable_path> [custom_config_path]"
#     echo "  reusable_path: path to reusable directory"
#     echo "  custom_config_path(optional): path to custom config file"
#     exit 1
#   fi
  
#   main "${2:-}"
# fi