#!/usr/bin/env bash
set -Eeuo pipefail

# Carrega helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shell-helpers.sh"

log "🔍 Detecting project stack..."

CURRENT_DIR="$(pwd)"
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
  log "❌ No stack signals found in $CURRENT_DIR"

  # Verifica se há manifestos em subpastas para dar dica precisa
  sub_signals=(*/package.json */composer.json */*.csproj */requirements.txt */go.mod)
  HINT_BLOCK=""
  if [[ ${#sub_signals[@]} -gt 0 ]]; then
    hint_dir="${sub_signals[0]%/*}"
    log "💡 Detected project files in subfolder: '${hint_dir}'"
    HINT_BLOCK=$(cat <<EOF
> [!WARNING]
> **Encontramos arquivos de projeto na subpasta:** \`${hint_dir}\`  
> 👉 Configure no seu workflow: \`project-path: ${hint_dir}\`
EOF
)
  fi

  # Renderiza o Job Summary usando template
  TEMPLATES_DIR="$SCRIPT_DIR/../../templates"
  append_template_to_summary "$TEMPLATES_DIR/summary-detect-stack-error.md" \
    CURRENT_DIR "$CURRENT_DIR" \
    HINT_BLOCK "$HINT_BLOCK"

  exit 1
fi

if [[ ${#SIGNALS[@]} -gt 1 ]]; then
  log "⚠️ Multiple stacks detected: ${SIGNALS[*]}"
  log "👉 Using first match: ${SIGNALS[0]}"
  log "👉 Override with 'stack' input for monorepos"
fi

log "✅ Detected stack: ${SIGNALS[0]}"
echo "${SIGNALS[0]}"
