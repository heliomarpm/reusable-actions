#!/bin/sh
set -e

echo "▶ Running Go coverage"

go test ./... -coverprofile=coverage.out

go tool cover -func=coverage.out | grep total > coverage-total.txt

LINE=$(awk '{print substr($3, 1, length($3)-1)}' coverage-total.txt)

mkdir -p coverage

cat <<EOF > coverage/coverage-summary.normalized.json
{
  "line": $LINE,
  "branch": $LINE,
  "function": $LINE
}
EOF

echo "Go coverage: $LINE%"
