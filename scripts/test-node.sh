#!/usr/bin/env bash
set -e

echo "📦 Installing dependencies..."
npm ci

echo "🧪 Running unit tests..."
npm test

echo "✅ Tests passed"