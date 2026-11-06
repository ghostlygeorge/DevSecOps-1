#!/usr/bin/env bash
# Demonstrates exit codes, pipes and pipefail without any scanners installed.
show() { echo "\$ $1"; bash -c "$1"; echo "  -> exit $?"; }
show 'true'
show 'false'
show 'ls /does-not-exist 2>/dev/null'
show 'exit 13'                                       # retire.js style
show 'false | tee /dev/null'                         # pipe masks failure
show 'set -o pipefail; false | tee /dev/null'        # pipefail restores it
show 'false || true'                                 # forced success
show 'exit 64'                                        # safety style
