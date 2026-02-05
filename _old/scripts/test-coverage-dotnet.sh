#!/bin/sh

dotnet test \
  /p:CollectCoverage=true \
  /p:CoverletOutput=coverage/ \
  /p:CoverletOutputFormat=json

jq '{
  line: .line,
  branch: .branch,
  function: .method
}' coverage/coverage.json > coverage/coverage-summary.normalized.json
