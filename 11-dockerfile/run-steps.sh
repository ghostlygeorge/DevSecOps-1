#!/usr/bin/env bash
# Build + run each step and report what happened. Takes a few minutes (apt).
cd "$(dirname "$0")"
for f in steps/Dockerfile.*; do
  tag="lab11-$(basename "$f" | cut -d. -f2)"
  echo "=============== $f"
  if docker build -q -t "$tag" -f "$f" . >/dev/null 2>&1; then
    docker rm -f "$tag" >/dev/null 2>&1
    docker run -d -it --name "$tag" "$tag" >/dev/null 2>&1
    sleep 3
    echo "build: OK   state: $(docker inspect -f '{{.State.Status}} (exit {{.State.ExitCode}})' "$tag" 2>/dev/null || echo 'failed to start')"
    docker rm -f "$tag" >/dev/null 2>&1
  else
    echo "build: FAILED"
  fi
done
