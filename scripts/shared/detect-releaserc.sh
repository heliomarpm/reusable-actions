#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILES=(
  ".releaserc"
  ".releaserc.json"
  ".releaserc.yaml"
  ".releaserc.yml"
  ".releaserc.js"
  ".releaserc.cjs"
  "release.config.js"
  "release.config.cjs"
)

# 1️⃣ Arquivo explícito
if [[ -n "$SEMANTIC_RELEASE_CONFIG" && -f "$SEMANTIC_RELEASE_CONFIG" ]]; then
  echo "$SEMANTIC_RELEASE_CONFIG"
  exit 0
fi

# 2️⃣ package.json com release
if [[ -f "package.json" ]]; then
  if jq -e '.release' package.json > /dev/null 2>&1; then
    echo "package.json"
    exit 0
  fi
fi

# 3️⃣ Arquivos padrão
for file in "${CONFIG_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo "$file"
    exit 0
  fi
done

# 4️⃣ Nenhum config encontrado
echo ""
exit 0
