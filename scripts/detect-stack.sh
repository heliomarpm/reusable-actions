#!/usr/bin/env bash
set -e

echo "🔍 Detecting project stack..."

if [ -f package.json ] || [ -f yarn.lock ] || [ -f pnpm-lock.yaml ]; then
  echo "node"
  exit 0
fi

if [ -f composer.json ] || [ -f "index.php" ] || [ -f "default.php" ]; then
  echo "php"
  exit 0
fi

if ls *.csproj >/dev/null 2>&1 || ls *.sln >/dev/null 2>&1; then
  echo "dotnet"
  exit 0
fi

if [ -f requirements.txt ] || [ -f pyproject.toml ] || [ -f Pipfile ] || [ -f uv.lock ] || [ -f poetry.lock ] || [ -f setup.py ]; then
  echo "python"
  exit 0
fi

if [ -f go.mod ]; then
  echo "go"
  exit 0
fi

echo "❌ Unable to detect project stack."
echo "👉 Supported stacks: node, php, dotnet, python, go"
echo "👉 You can override by setting STACK env variable."
exit 1
