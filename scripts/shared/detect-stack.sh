#!/usr/bin/env bash
set -Eeuo pipefail

# Carrega helpers (se não carregado via BASH_ENV)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shell-helpers.sh"

log "🔍 Detecting project stack..."

SIGNALS=()

# Coleta todos os sinais
[[ -f package.json || -f yarn.lock || -f pnpm-lock.yaml ]] && SIGNALS+=("node")
[[ -f composer.json || -f index.php ]]                     && SIGNALS+=("php")

shopt -s nullglob
dotnet_files=(*.csproj *.sln)
[[ ${#dotnet_files[@]} -gt 0 ]] && SIGNALS+=("dotnet")

[[ -f requirements.txt || -f pyproject.toml || -f Pipfile || -f uv.lock || -f setup.py ]] && SIGNALS+=("python")
[[ -f go.mod ]]                                             && SIGNALS+=("go")

if [[ ${#SIGNALS[@]} -eq 0 ]]; then
  log "❌ No stack signals found"
  log "👉 Supported: node, php, dotnet, python, go"
  exit 1
fi

if [[ ${#SIGNALS[@]} -gt 1 ]]; then
  log "⚠️ Multiple stacks detected: ${SIGNALS[*]}"
  log "👉 Using first match: ${SIGNALS[0]}"
  log "👉 Override with 'stack' input for monorepos"
fi

log "✅ Detected stack: ${SIGNALS[0]}"
echo "${SIGNALS[0]}"
