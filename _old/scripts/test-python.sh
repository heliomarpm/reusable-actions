#!/usr/bin/env bash
set -e

echo "🐍 Running Python tests..."

if [ -f uv.lock ]; then
  echo "📦 Installing dependencies with UV..."
  uv sync
  echo "🧪 Running unit tests..."
  uv run pytest

elif command -v poetry >/dev/null 2>&1 && [ -f poetry.lock ]; then
  echo "📦 Installing dependencies with Poetry..."
  poetry install
  echo "🧪 Running unit tests..."
  poetry run pytest

elif [ -f requirements.txt ]; then
  echo "📦 Installing dependencies with pip..."
  pip install -r requirements.txt
  echo "🧪 Running unit tests..."
  pytest

else
  echo "❌ No supported Python dependency manager found."
  echo "👉 Supported: uv, poetry, pip"
  exit 1
fi

echo "✅ Unit tests passed"