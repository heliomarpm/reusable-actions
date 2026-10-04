#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shell-helpers.sh"


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

run() {  
  # 1. Instala dependências do projeto se houver lockfile
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
  fi

  # 2. Garante que os pacotes do semantic-release estão sempre disponíveis
  install_toolchain
}

run