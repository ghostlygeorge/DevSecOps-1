#!/usr/bin/env bash
# Either method installs Chef InSpec 5.22.29 (used throughout labs 71-79).
set -e
if command -v dpkg >/dev/null; then
  wget -q https://packages.chef.io/files/stable/inspec/5.22.29/ubuntu/18.04/inspec_5.22.29-1_amd64.deb
  dpkg -i inspec_5.22.29-1_amd64.deb
else
  curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 5.22.29 -P inspec
fi
# Avoid the ssh yes/no prompt when targeting remote hosts (trust-on-first-use):
grep -q "StrictHostKeyChecking accept-new" ~/.ssh/config 2>/dev/null || echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config
inspec version --chef-license accept
