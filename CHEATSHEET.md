# DevSecOps Exam Cheat-Sheet

Condensed from labs 00–85. Hostnames use `$VARS` from `lab-env.sh`.

## The universal job template (GitLab)

```yaml
<tool>:
  stage: build|test|integration|prod           # SAST/secrets: build. SCA: test. DAST: integration (after deploy). Compliance: prod
  script:
    - docker run --rm -v $(pwd):/src <image> <args> -o /src/<report>.json   # or: ... | tee <report>.json
  artifacts:
    paths: [<report>.json]
    when: always                                # keep the report even when the job failed
    expire_in: one week
  allow_failure: true                           # ML 1-2: report, don't block
```

| | GitLab | Jenkins | GitHub Actions |
|---|---|---|---|
| don't fail | `allow_failure: true` | `catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') { }` | `continue-on-error: true` (on the step) |
| keep report | `artifacts: when: always` | `post { always { archiveArtifacts artifacts: 'x.json', fingerprint: true } }` | `actions/upload-artifact@v4` + `if: always()` |
| secret | CI/CD Variables | `withCredentials([string(credentialsId:'id', variable:'V')])` | `${{ secrets.NAME }}` |
| `$(pwd)` | `$(pwd)` | `\$(pwd)` inside `sh "..."` | `$(pwd)` |
| order | `stages:` | stage order | `needs:` (otherwise parallel!) |
| manual | `when: manual` | `input "Deploy?"` | environment reviewers |

## Commands per tool

| Tool | Local | Docker / CI | Report | FP / ignore mechanism |
|---|---|---|---|---|
| Safety | `safety check -r requirements.txt --json` | `docker run -v $(pwd):/src --rm hysnsec/safety check -r requirements.txt --json \| tee oast-results.json` | stdout | `-i ID`, `.safety-policy.yml` |
| Retire.js | `npm install; retire --outputformat json --outputpath r.json --severity high` | `node:alpine3.10` + `npm i -g retire` | `--outputpath` | `.retireignore.json` → `--ignorefile` |
| Dependency-Check | `dependency-check.sh --scan . --format JSON --project X --failOnCVSS 4 --out /opt` | `run-depcheck.sh` (hysnsec/dependency-check) | `--out` | `--suppression suppression.xml` |
| Snyk | `snyk auth $T; npm install; snyk test --strict-out-of-sync=false --json` | `snyk-alpine` binary on node alpine | stdout | `.snyk` / `snyk ignore` |
| AuditJS | `npm install; auditjs ossi -q -j` | `hysnsec/auditjs ossi -q -j` (`-w /src`) | stdout | `-w whitelist` |
| bundler-audit | – | `hysnsec/bundle-audit check --format json --output f.json` | `--output` | `--ignore CVE` |
| OSV | `osv-scanner -L package-lock.json` | `go install .../osv-scanner@v1; osv-scanner --json .` | stdout | `osv-scanner.toml` `[[IgnoredVulns]]` / `--config=` |
| Trivy | `trivy fs .` | `trivy fs --exit-code 1 --severity HIGH,CRITICAL -f json -o t.json .` | `-o` | `.trivyignore` |
| TruffleHog | `trufflehog git <url> --json` | `hysnsec/trufflehog filesystem --directory=/src --fail --json` | stdout | – (verify/rotate) |
| detect-secrets | `detect-secrets scan . > base.json; detect-secrets audit base.json` | – | stdout | baseline `is_secret: false` |
| Talisman | hook; `talisman --scan` | – | `talisman_reports/` | `.talismanrc` checksum |
| Gitleaks | – | `zricethezav/gitleaks detect --source . --report-format json --report-path g.json` | `--report-path` | `.gitleaks.toml` allowlist, `.gitleaksignore` |
| Bandit | `bandit -r . -f json -o b.json` | `hysnsec/bandit -r /src -f json -o /src/b.json` | `-o` | **`-b baseline.json`** (keep only FPs) |
| Brakeman | `brakeman -f json` | `hysnsec/brakeman -f json /src` | stdout/`-o` | `-i brakeman.ignore` (fingerprint) |
| Gosec | `gosec -fmt=json -out=g.json ./...` | `securego/gosec -fmt json -out g.json ./...` (`-w /src`) | `-out` | `#nosec`, `-exclude=G104` |
| Semgrep | `semgrep --config auto --json -o s.json` | `returntocorp/semgrep semgrep --config auto --output s.json --json` | `--output` | `# nosemgrep`, `.semgrepignore` |
| Hadolint | `hadolint Dockerfile` | `hadolint/hadolint` | `-f json` | `--ignore DL3018`, `.hadolint.yaml` |
| Pylint | `pylint pkg/*.py -f json` | – | stdout | `.pylintrc` `disable=` |
| SonarQube | `sonar-scanner -Dsonar.projectKey=X -Dsonar.sources=. -Dsonar.host.url=$SONAR_URL -Dsonar.login=$T` | add `-Dsonar.qualitygate.wait=true` | server | Quality Profiles / mark issue |
| Nikto | `./nikto.pl -h $PROD_HOST -output n.xml` | `hysnsec/nikto -h URL -o /tmp/n.xml` (`-v $(pwd):/tmp`) | `-output` | `SKIPIDS` in nikto.conf |
| SSLyze | `sslyze --json_out s.json host:443` | `hysnsec/sslyze host:443 --json_out /tmp/s.json` | `--json_out` | – |
| Nmap | `nmap $PROD_HOST -oX n.xml` | `hysnsec/nmap host -oX /tmp/n.xml` | `-oX` | – |
| ZAP baseline | – | `docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t $PROD_URL -J z.json` | `-J/-x/-r` (under /zap/wrk) | **`-c default.conf`** (TABS; FAIL/IGNORE/OUTOFSCOPE), `-p progress.json` |
| Dastardly | – | `-e BURP_START_URL=... -e BURP_REPORT_FILE_PATH=/dastardly/d.xml` | JUnit XML | – |
| Nuclei | `nuclei -u $PROD_URL -j -o n.json` | `projectdiscovery/nuclei:v2.9.6 -u URL -j -o n.json` (`-w /nuclei`) | `-o` | `-eid`, `-etags`, workflows `-w` |
| Ansible | `ansible-playbook -i inventory.ini ansible-hardening.yml` | `willhallonline/ansible` | – | role vars |
| TFLint | `tflint --chdir=aws -f json` | GHA `setup-tflint` | stdout | `--disable-rule` |
| Checkov | `checkov -d aws -o json` | `bridgecrew/checkov -d aws -o json` (`-w /src`) | stdout | `--skip-check`, `#checkov:skip=ID:why`, `--baseline` |
| Terrascan | `terrascan scan -d aws -o json` | image + `entrypoint: ["/bin/sh","-c"]`, `/go/bin/terrascan` | stdout | `--skip-rules`, `#ts:skip=` |
| tfsec | `tfsec aws -f json` | `aquasec/tfsec /src -f json` | stdout | `-e`, `#tfsec:ignore:ID` |
| KICS | – | `checkmarx/kics:v1.7.11 scan --path /path --output-path /path --report-formats html` | `--output-path` | `--exclude-queries` |
| InSpec | `inspec exec <profile> -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept --reporter cli json:i.json` | `hysnsec/inspec` (**`/share`**) | `--reporter json:` | `skip_control` in wrapper profile |
| Lynis | `lynis audit system` | – | `/var/log/lynis-report.dat` | `custom.prf` |

## Exit codes that will surprise you
`| tee` → always 0 (use `set -o pipefail`) · retire 13 · safety 64 · trufflehog `--fail` 183 ·
brakeman 3 · terrascan 3 · tflint 2 · inspec 100 · ZAP 1 FAIL / 2 WARN · DC needs `--failOnCVSS` ·
nuclei, trivy, sonar-scanner, semgrep scan: 0 unless told otherwise. Full table: [lab 06](06-exit-codes/README.md).

## Deploy / SSH block (memorise)

```yaml
before_script:
  - mkdir -p ~/.ssh
  - echo "$PROD_SSH_PRIVKEY" | tr -d '\r' > ~/.ssh/id_rsa
  - chmod 600 ~/.ssh/id_rsa
  - eval "$(ssh-agent -s)"
  - ssh-add ~/.ssh/id_rsa
  - ssh-keyscan -t rsa $PROD_HOSTNAME >> ~/.ssh/known_hosts
script:
  - |
    ssh $PROD_USERNAME@$PROD_HOSTNAME << EOF
      docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
      docker rm -f django.nv
      docker run -d --name django.nv -p 8000:8000 $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    EOF
```
Release: `echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY`.
Alpine images need `apk add openssh-client` for ssh-agent/keyscan.

## DefectDojo
```bash
export API_KEY=$(curl -s -XPOST -H 'content-type: application/json' $DOJO_URL/api/v2/api-token-auth/ -d '{"username":"root","password":"pdso-training"}' | jq -r .token)
python3 upload-results.py --host $DOJO_HOST --api_key $API_KEY --engagement_id 1 --product_id 1 --lead_id 1 --environment "Production" --result_file bandit-output.json --scanner "Bandit Scan"
```
Parser names: `Bandit Scan`, `ZAP Scan` (**XML** `-x`), `Brakeman Scan`, `Retire.js Scan`,
`Dependency Check Scan`, `Gitleaks Scan`, `Trufflehog Scan`, `Semgrep JSON Report`, `Checkov Scan`,
`TFSec Scan`, `KICS Scan`, `Nuclei Scan`, `Nmap Scan`, `Nikto Scan`, `SSLyze Scan (JSON)`, `Trivy Scan`.
500 = wrong environment name / parser / format. In CI, put the upload in **`after_script`** (GitLab), after `|| true` (Jenkins), or behind `if: always()` (GHA).

## Things graders and real life care about
1. Ran it locally before CI? Show the command and output.
2. Machine-readable report saved as an artifact?
3. Non-blocking at ML 1–2, with a reason.
4. False positives handled **programmatically** (baseline/config/ignore file), not `# nosec`.
5. Right stage: secrets/SAST early, SCA before packaging, DAST after deploy, compliance on prod.
6. Results centralised (DefectDojo) and de-duplicated.
