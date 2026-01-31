#!/usr/bin/env bash
set -e

if [ ! -f composer.json ]; then
  echo "❌ composer.json not found"
  exit 1
fi

echo "📦 Installing dependencies..."
composer install --no-interaction --prefer-dist

if [ ! -f vendor/bin/phpunit ]; then
  echo "❌ PHPUnit not found"
  exit 1
fi

echo "🧪 Running unit tests..."
vendor/bin/phpunit

echo "✅ Unit tests passed"