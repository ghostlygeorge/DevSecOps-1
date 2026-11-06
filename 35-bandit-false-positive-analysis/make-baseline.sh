#!/usr/bin/env bash
# Build a baseline programmatically instead of hand-editing JSON:
# keep only the findings you've triaged as false positives, selected by
# test_id + filename + line.  Usage (inside the scanned repo):
#   ../35-bandit-false-positive-analysis/make-baseline.sh B608:./flaskblog/blogapi/dashboard.py:133 [more...]
set -euo pipefail
bandit -r . -f json -q --exit-zero > /tmp/bandit-all.json
filter='false'
for spec in "$@"; do
  IFS=: read -r tid file line <<<"$spec"
  filter="$filter or (.test_id==\"$tid\" and .filename==\"$file\" and .line_number==$line)"
done
jq "{results: [.results[] | select($filter)]}" /tmp/bandit-all.json > baseline.json
echo "baseline.json contains $(jq '.results|length' baseline.json) false positive(s)"
