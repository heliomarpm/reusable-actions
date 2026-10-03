#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../shared/shell-helpers.sh"

echo "📊 Running PHP coverage..."

if [[ -f vendor/bin/phpunit ]]; then
  vendor/bin/phpunit --coverage-text --coverage-clover coverage/clover.xml
elif [[ -f vendor/bin/pest ]]; then
  vendor/bin/pest --coverage --coverage-clover coverage/clover.xml
else
  echo "⚠️ No coverage runner found"
  exit 0
fi

# Normalizar output
if [[ -f coverage/clover.xml ]]; then
  LINE=$(php -r "
    \$xml = simplexml_load_file('coverage/clover.xml');
    \$metrics = \$xml->project->metrics;
    \$total = (int)\$metrics['statements'];
    \$covered = (int)\$metrics['coveredstatements'];
    echo \$total > 0 ? round((\$covered/\$total)*100, 2) : 0;
  ")

  mkdir -p coverage
  cat <<EOF > coverage/coverage-summary.normalized.json
{
  "line": $LINE,
  "branch": $LINE,
  "function": $LINE
}
EOF

  echo "✅ PHP coverage normalized: $LINE%"
else
  echo "⚠️ No coverage output generated"
fi
