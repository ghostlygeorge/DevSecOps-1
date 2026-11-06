#!/usr/bin/env bash
# Source this file at the start of every lab session:
#   export LAB_ID=jbekkra7        # <- your machine id (shown by `hostname` on the DevSecOps-Box)
#   source /path/to/DevSecOps/lab-env.sh
#
# Every README in this repo refers to hosts through these variables, and every
# pipeline/config file uses the literal token LABID, which `labify` rewrites.

if [ -z "${LAB_ID:-}" ]; then
  # DevSecOps-Box hostname is devsecops-box-<id>; derive the id from it if possible
  case "$(hostname)" in
    devsecops-box-*) LAB_ID="${HOSTNAME#devsecops-box-}" ;;
    *) echo "[lab-env] LAB_ID not set and hostname is not devsecops-box-*; export LAB_ID first" >&2 ;;
  esac
fi
export LAB_ID

export LAB_DOMAIN="lab.practical-devsecops.training"

# Short hostnames (resolve inside the lab network, used for ssh / nmap / ansible)
export DSO_BOX="devsecops-box-${LAB_ID}"
export GITLAB_HOST="gitlab-ce-${LAB_ID}"
export PROD_HOST="prod-${LAB_ID}"
export SANDBOX_HOST="sandbox-${LAB_ID}"
export DOJO_HOST_SHORT="dojo-${LAB_ID}"

# Public URLs (browser / https tools)
export GITLAB_URL="https://gitlab-ce-${LAB_ID}.${LAB_DOMAIN}"
export JENKINS_URL="https://jenkins-${LAB_ID}.${LAB_DOMAIN}"
export PROD_URL="https://prod-${LAB_ID}.${LAB_DOMAIN}"
export SANDBOX_URL="https://sandbox-${LAB_ID}.${LAB_DOMAIN}"
export DOJO_HOST="dojo-${LAB_ID}.${LAB_DOMAIN}"
export DOJO_URL="https://${DOJO_HOST}"
export SONAR_URL="https://sonarqube-${LAB_ID}.${LAB_DOMAIN}"
export REGISTRY_HOST="registry-${LAB_ID}.${LAB_DOMAIN}"
export GITLAB_REGISTRY_HOST="gitlab-registry-${LAB_ID}.${LAB_DOMAIN}"
export DSO_BOX_URL="https://devsecops-box-${LAB_ID}.${LAB_DOMAIN}"

# Default lab credentials (training environment only)
export LAB_USER="root"
export LAB_PASS="pdso-training"

# Rewrite the LABID token in pipeline/config files into your real lab id.
#   labify .gitlab-ci.yml Jenkinsfile
labify() {
  [ -n "$LAB_ID" ] || { echo "LAB_ID not set" >&2; return 1; }
  sed -i "s/LABID/${LAB_ID}/g" "$@"
}

# Print a pipeline/config file with LABID substituted, without touching it
# (handy for copy-pasting into the GitLab web editor):
#   labcat 34-sast-bandit/ci/.gitlab-ci.yml
labcat() { sed "s/LABID/${LAB_ID}/g" "$@"; }

# Fetch a DefectDojo API token into $API_KEY
dojo_token() {
  API_KEY=$(curl -s -XPOST -H 'content-type: application/json' \
    "${DOJO_URL}/api/v2/api-token-auth/" \
    -d "{\"username\": \"${LAB_USER}\", \"password\": \"${LAB_PASS}\"}" | jq -r '.token')
  export API_KEY
  echo "API_KEY=${API_KEY}"
}

echo "[lab-env] LAB_ID=${LAB_ID}  gitlab=${GITLAB_URL}  prod=${PROD_URL}"
