#!/usr/bin/env bash
set -e

echo "📦 Downloading dependencies..."
go mod download

echo "🧪 Running unit tests..."
go test ./...

echo "✅ Unit tests passed"