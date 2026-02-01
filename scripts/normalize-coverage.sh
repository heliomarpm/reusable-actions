#!/bin/sh

INPUT="$1"
OUTPUT="coverage/coverage-summary.normalized.json"

if [ ! -f "$INPUT" ]; then
  echo "Coverage file not found"
  exit 1
fi

cp "$INPUT" "$OUTPUT"
