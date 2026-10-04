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

  # Verifica se há manifestos em subpastas para auto-detecção ou dica precisa
  sub_signals=()
  for f in */package.json */composer.json */*.csproj */requirements.txt */go.mod; do
    if [[ -f "$f" ]]; then
      local_dir="${f%/*}"
      if [[ "$local_dir" != "node_modules" && "$local_dir" != "__reusable_actions__" && "$local_dir" != ".github" && "$local_dir" != "vendor" ]]; then
        sub_signals+=("$f")
      fi
    fi
  done

  HINT_BLOCK=""
  if [[ ${#sub_signals[@]} -gt 0 ]]; then
    sub_dirs=()
    for s in "${sub_signals[@]}"; do
      sub_dirs+=("${s%/*}")
    done
    unique_sub_dirs=($(echo "${sub_dirs[@]}" | tr ' ' '\n' | sort -u))

    if [[ ${#unique_sub_dirs[@]} -eq 1 ]]; then
      hint_dir="${unique_sub_dirs[0]}"
      log "💡 Auto-detected project stack in subfolder: '${hint_dir}'"
      case "${sub_signals[0]}" in
        */package.json) echo "node"; exit 0 ;;
        */composer.json) echo "php"; exit 0 ;;
        */*.csproj) echo "dotnet"; exit 0 ;;
        */requirements.txt) echo "python"; exit 0 ;;
        */go.mod) echo "go"; exit 0 ;;
      esac
    fi

    hint_dir="${unique_sub_dirs[0]}"
    HINT_BLOCK=$(cat <<EOF
> [!WARNING]
> **Encontramos arquivos de projeto na subpasta:** \`${hint_dir}\`  
> 👉 Configure no seu workflow: \`project-path: ${hint_dir}\`
EOF
)
  fi

  # Renderiza o Job Summary usando template se não conseguir resolver
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
