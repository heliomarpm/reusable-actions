#!/bin/sh

npm install
npm test -- --coverage --coverageReporters=json-summary

mkdir -p coverage
jq '{
  line: .total.lines.pct,
  branch: .total.branches.pct,
  function: .total.functions.pct
}' coverage/coverage-summary.json > coverage/coverage-summary.normalized.json
