#!/usr/bin/env bash
set -e

echo "🚀 Starting release process..."

CURRENT_VERSION=$(git tag --sort=-v:refname | head -n 1)
CURRENT_VERSION=${CURRENT_VERSION:-v0.0.0}

echo "🔖 Current version: $CURRENT_VERSION"

COMMITS=$(git log "$CURRENT_VERSION"..HEAD --pretty=format:"%s%n%b")

NEXT_VERSION=$(./scripts/version.sh "$CURRENT_VERSION" "$COMMITS")

echo "📦 Next version: $NEXT_VERSION"

./scripts/changelog.sh "$NEXT_VERSION" "$COMMITS"

git add CHANGELOG.md
git commit -m "chore(release): $NEXT_VERSION"

git tag "$NEXT_VERSION"
git push origin main --tags

gh release create "$NEXT_VERSION" --notes-file CHANGELOG.md

echo "✅ Release $NEXT_VERSION created"
