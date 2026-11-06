#!/bin/sh
# Commit this to the webgoat repo root. The NVD data dir is persisted under
# $PWD/data so repeated runs (or a CI cache on data/) don't re-download the
# whole NVD feed every time.
DATA_DIRECTORY="$PWD/data"
REPORT_DIRECTORY="$PWD/reports"

if [ ! -d "$DATA_DIRECTORY" ]; then
    echo "Initially creating persistent directories"
    mkdir -p "$DATA_DIRECTORY"
    chmod -R 777 "$DATA_DIRECTORY"

    mkdir -p "$REPORT_DIRECTORY"
    chmod -R 777 "$REPORT_DIRECTORY"
fi

docker run --rm \
    --volume $(pwd):/src \
    --volume "$DATA_DIRECTORY":/usr/share/dependency-check/data \
    --volume "$REPORT_DIRECTORY":/reports \
    hysnsec/dependency-check \
    --scan /src \
    --format "JSON" \
    --project "Webgoat" \
    --failOnCVSS 4 \
    --out /reports
