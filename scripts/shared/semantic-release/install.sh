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
  local target_dir="${PROJECT_PATH:-.}"
  if [[ "$target_dir" != "." && -d "$target_dir" ]]; then
    log "Installing project dependencies in $target_dir"
    (
      cd "$target_dir"
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
    )
  else
    # 1. Instala dependências do projeto se houver lockfile no diretório atual
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
  fi

  # 2. Garante que os pacotes do semantic-release estão sempre disponíveis
  install_toolchain
}

run