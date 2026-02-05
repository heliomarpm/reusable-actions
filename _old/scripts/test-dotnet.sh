#!/usr/bin/env bash
set -e

echo "📦 Restoring packages..."
dotnet restore

echo "🧪 Running unit tests..."
dotnet test --no-build --verbosity normal

echo "✅ Unit tests passed"