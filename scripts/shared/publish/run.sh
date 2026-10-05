#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REUSABLE_PATH="${REUSABLE_PATH:-$SCRIPT_DIR/../../..}"

# Carrega helpers se existirem
if [[ -f "$SCRIPT_DIR/../shell-helpers.sh" ]]; then
  source "$SCRIPT_DIR/../shell-helpers.sh"
else
  log() { echo "→ $*" >&2; }
  fail() { echo "::error::$*" >&2; exit 1; }
fi

log "🚀 Publish Engine - Initializing"

PROJECT_PATH="${PROJECT_PATH:-.}"
STACK="${STACK:-}"
REGISTRIES="${REGISTRIES:-${REGISTRY:-github}}"
PUBLISH_COMMAND="${PUBLISH_COMMAND:-}"
DRY_RUN="${DRY_RUN:-false}"
INPUT_VERSION="${INPUT_VERSION:-}"

cd "$PROJECT_PATH"

# Auto-detect stack se não fornecida
if [[ -z "$STACK" && -z "$PUBLISH_COMMAND" ]]; then
  DETECT_STACK_SCRIPT="$REUSABLE_PATH/scripts/shared/detect-stack.sh"
  if [[ -f "$DETECT_STACK_SCRIPT" ]]; then
    STACK=$(bash "$DETECT_STACK_SCRIPT" "." 2>/dev/null || true)
  fi
fi
STACK="${STACK:-node}"
log "🧱 Target stack: $STACK"
log "📂 Working directory: $(pwd)"
log "🎯 Registries: $REGISTRIES"
log "🧪 Dry run: $DRY_RUN"

# Separa a lista de registries por vírgula
IFS=',' read -ra REGISTRY_LIST <<< "$REGISTRIES"

TOTAL_SUCCESS=0
TOTAL_FAILED=0
SUMMARY_ROWS=""

for raw_reg in "${REGISTRY_LIST[@]}"; do
  REG="$(echo "$raw_reg" | xargs | tr '[:upper:]' '[:lower:]')"
  [[ -z "$REG" ]] && continue

  log "──────────── Publishing to registry: $REG ────────────"
  
  # Resolve o token apropriado para este registry
  CURRENT_TOKEN=""
  case "$REG" in
    github|gh|ghcr)
      CURRENT_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-${TOKEN:-${PUBLISH_TOKEN:-}}}}"
      ;;
    npm|npmjs)
      CURRENT_TOKEN="${NPM_TOKEN:-${TOKEN:-${PUBLISH_TOKEN:-}}}"
      ;;
    pypi)
      CURRENT_TOKEN="${PYPI_TOKEN:-${TOKEN:-${PUBLISH_TOKEN:-}}}"
      ;;
    nuget)
      CURRENT_TOKEN="${NUGET_TOKEN:-${TOKEN:-${PUBLISH_TOKEN:-}}}"
      ;;
    *)
      CURRENT_TOKEN="${TOKEN:-${PUBLISH_TOKEN:-}}"
      ;;
  esac

  # Configura autenticação do registry
  NPMRC_CREATED=false
  if [[ "$STACK" == "node" ]]; then
    if [[ "$REG" == "github" || "$REG" == "gh" ]]; then
      OWNER="${GITHUB_REPOSITORY_OWNER:-}"
      if [[ -z "$OWNER" && -n "${GITHUB_REPOSITORY:-}" ]]; then
        OWNER="${GITHUB_REPOSITORY%%/*}"
      fi
      
      [[ -f .npmrc ]] && cp .npmrc .npmrc.bak
      NPMRC_CREATED=true

      {
        if [[ -n "$OWNER" ]]; then
          echo "@${OWNER,,}:registry=https://npm.pkg.github.com"
        fi
        echo "//npm.pkg.github.com/:_authToken=${CURRENT_TOKEN}"
      } >> .npmrc

    elif [[ "$REG" == "npm" || "$REG" == "npmjs" ]]; then
      [[ -f .npmrc ]] && cp .npmrc .npmrc.bak
      NPMRC_CREATED=true
      echo "//registry.npmjs.org/:_authToken=${CURRENT_TOKEN}" >> .npmrc
    fi
  fi

  # Executa o comando de publicação
  STATUS="success"
  
  if [[ -n "$PUBLISH_COMMAND" ]]; then
    log "Executing custom publish command: $PUBLISH_COMMAND"
    if ! eval "$PUBLISH_COMMAND"; then
      STATUS="failed"
    fi
  else
    PLUGIN_SCRIPT="$REUSABLE_PATH/scripts/plugins/$STACK/publish.sh"
    if [[ -f "$PLUGIN_SCRIPT" ]]; then
      chmod +x "$PLUGIN_SCRIPT"
      export REGISTRY="$REG"
      export DRY_RUN="$DRY_RUN"
      export NEXT_VERSION="$INPUT_VERSION"
      export PUBLISH_TOKEN="$CURRENT_TOKEN"
      if ! "$PLUGIN_SCRIPT"; then
        STATUS="failed"
      fi
    else
      log "⚠️ No publish.sh found for stack '$STACK'. Skipping."
      STATUS="skipped"
    fi
  fi

  # Limpa autenticação temporária
  if [[ "$NPMRC_CREATED" == "true" ]]; then
    rm -f .npmrc
    [[ -f .npmrc.bak ]] && mv .npmrc.bak .npmrc
  fi

  if [[ "$STATUS" == "success" ]]; then
    log "✅ Successfully published to $REG"
    TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    SUMMARY_ROWS="${SUMMARY_ROWS}
| \`$REG\` | \`$STACK\` | ✅ Sucesso |"
  elif [[ "$STATUS" == "skipped" ]]; then
    SUMMARY_ROWS="${SUMMARY_ROWS}
| \`$REG\` | \`$STACK\` | ⚠️ Ignorado (sem plugin) |"
  else
    log "❌ Failed to publish to $REG"
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
    SUMMARY_ROWS="${SUMMARY_ROWS}
| \`$REG\` | \`$STACK\` | ❌ Falhou |"
  fi
done

# Escreve resumo no GITHUB_STEP_SUMMARY
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## 📦 CD Publish Summary"
    echo ""
    echo "- **Stack:** \`$STACK\`"
    echo "- **Modo Simulação (Dry Run):** \`$DRY_RUN\`"
    echo ""
    echo "| Registry | Stack | Status |"
    echo "| :--- | :--- | :--- |"
    echo -e "$SUMMARY_ROWS"
    echo ""
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "published=$([[ $TOTAL_FAILED -eq 0 && $TOTAL_SUCCESS -gt 0 ]] && echo 'true' || echo 'false')" >> "$GITHUB_OUTPUT"
  echo "total_success=$TOTAL_SUCCESS" >> "$GITHUB_OUTPUT"
  echo "total_failed=$TOTAL_FAILED" >> "$GITHUB_OUTPUT"
fi

if [[ $TOTAL_FAILED -gt 0 ]]; then
  fail "Publish failed for $TOTAL_FAILED registry/registries."
fi

log "🎉 Publish process completed successfully!"
