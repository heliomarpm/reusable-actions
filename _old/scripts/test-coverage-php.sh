#!/bin/sh
set -e

echo "▶ Running PHP coverage"

if ! command -v phpunit >/dev/null 2>&1; then
  ./vendor/bin/phpunit --coverage-clover coverage.xml
else
  phpunit --coverage-clover coverage.xml
fi

mkdir -p coverage

LINE=$(php -r '
$xml = simplexml_load_file("coverage.xml");
$metrics = $xml->project->metrics;
$total = (int)$metrics["elements"];
$covered = (int)$metrics["coveredelements"];
echo $total > 0 ? round(($covered / $total) * 100, 2) : 0;
')

cat <<EOF > coverage/coverage-summary.normalized.json
{
  "line": $LINE,
  "branch": $LINE,
  "function": $LINE
}
EOF

echo "PHP coverage: $LINE%"
