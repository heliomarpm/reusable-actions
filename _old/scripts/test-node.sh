#!/usr/bin/env bash
set -e

echo "📦 Installing dependencies..."

if [ -f pnpm-lock.yaml ]; then
  echo "➡️ Using pnpm"
  corepack enable
  pnpm install --frozen-lockfile
elif [ -f yarn.lock ]; then
  echo "➡️ Using yarn"
  yarn install --frozen-lockfile
elif [ -f package-lock.json ]; then
  echo "➡️ Using npm ci"
  npm ci
else
  echo "➡️ Using npm install (no lockfile found)"
  npm install
fi

echo "🧪 Running unit tests..."
npm test

echo "✅ Node.js tests passed"
