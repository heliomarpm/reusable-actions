#!/bin/sh

pip install -r requirements.txt
pytest --cov --cov-report=json

jq '{
  line: .totals.percent_covered,
  branch: .totals.percent_covered,
  function: .totals.percent_covered
}' coverage.json > coverage/coverage-summary.normalized.json
