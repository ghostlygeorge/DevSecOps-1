#!/usr/bin/env bash
# Challenge answer: make prod pass ubuntu-1.3.2 and 1.3.3.
# The course profile greps /etc/sudoers itself (not /etc/sudoers.d/), so the lines
# must go there. Back up first and validate with visudo: a broken sudoers file
# locks everyone out of sudo.
set -euo pipefail
: "${PROD_HOST:?source lab-env.sh first}"
ssh root@"$PROD_HOST" bash -s <<'REMOTE'
set -e
cp /etc/sudoers /etc/sudoers.bak.$(date +%s)
grep -q '^Defaults use_pty' /etc/sudoers || echo 'Defaults use_pty' >> /etc/sudoers
grep -q '^Defaults logfile=' /etc/sudoers || echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers
visudo -c
REMOTE
