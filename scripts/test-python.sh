#!/usr/bin/env bash
set -e

if command -v poetry >/dev/null 2>&1; then
  echo "📦 Installing dependencies with Poetry..."
  poetry install
  echo "🧪 Running unit tests..."
  poetry run pytest
else
  echo "📦 Installing dependencies with pip..."
  pip install -r requirements.txt
  echo "🧪 Running unit tests..."
  pytest
fi

echo "✅ Unit tests passed"