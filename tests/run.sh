#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BATS_BIN="bats"
if ! command -v "$BATS_BIN" >/dev/null 2>&1; then
  TOOLS_DIR="$ROOT_DIR/.tools"
  BATS_REPO="$TOOLS_DIR/bats-core"
  if [[ ! -x "$BATS_REPO/bin/bats" ]]; then
    echo "📦 Baixando Bats-Core para execução local em $BATS_REPO..."
    mkdir -p "$TOOLS_DIR"
    git clone --depth 1 https://github.com/bats-core/bats-core.git "$BATS_REPO" >/dev/null 2>&1
  fi
  BATS_BIN="$BATS_REPO/bin/bats"
fi

echo "🚀 Executando suíte de testes com $($BATS_BIN -v)..."

if [[ $# -gt 0 ]]; then
  "$BATS_BIN" "$@"
else
  "$BATS_BIN" tests/unit/*.bats
fi
