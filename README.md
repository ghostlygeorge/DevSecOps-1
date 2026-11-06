# DevSecOps Labs (Certified DevSecOps Professional)

86 hands-on labs (00–85) covering the CDP course end to end: Linux, Git,
and Docker fundamentals; CI/CD on GitLab, Jenkins, and GitHub Actions; SCA,
secrets scanning, SAST, and DAST; IaC security and hardening;
Compliance as Code; vulnerability management with DefectDojo; and a
capstone pipeline.

Each lab has a `README.md` (Goal → Setup → Steps → Challenges with answers →
Notes/errata) plus the real files it uses: pipelines (`ci/gitlab-ci.yml`,
`ci/Jenkinsfile`, `ci/github-actions.yaml`), rules, configs, InSpec profiles,
Nuclei templates, and helper scripts.

> **Exam focus:** the exam is open-book, but you won't have the lab
> instructions. This repo is meant to be your notes. **GitLab CI** is the
> exam's CI system, so master the GitLab variants first. Quick reference:
> [CHEATSHEET.md](CHEATSHEET.md).

## Start here

```bash
export LAB_ID=jbekkra7                 # your machine id (hostname suffix of the DevSecOps-Box)
source /path/to/DevSecOps/lab-env.sh   # exports $PROD_HOST $GITLAB_URL $DOJO_URL ... + helpers
labcat 34-sast-bandit/ci/gitlab-ci.yml # print a pipeline with LABID replaced, ready to paste
```

Every config/pipeline file uses the literal token **`LABID`** in hostnames.
`labify <file>` rewrites it in place, and `labcat <file>` prints it substituted.
`dojo_token` fetches a DefectDojo API key into `$API_KEY`.

## Fundamentals

| Lab | Topic |
|---|---|
| [00-exam-and-lab-setup](00-exam-and-lab-setup/README.md) | Exam rules and strategy, lab machines, 2-hour lifetimes, this repo's conventions |
| [01-linux-basics](01-linux-basics/README.md) | Heredocs (quoted vs unquoted), redirection, `tee`, pipes, permissions, `sudo -S` |
| [02-git-basics](02-git-basics/README.md) | Clone/commit/push, branch vs checkout vs switch, MRs, pull, cleanup |
| [03-ssh](03-ssh/README.md) | Remote commands, `ssh-keyscan` vs `accept-new` vs `StrictHostKeyChecking=no`, the CI key pattern |
| [04-jq](04-jq/README.md) | JSON filtering, `select`, `length`, scanner one-liners (+ runnable solutions) |
| [05-http-server-and-find](05-http-server-and-find/README.md) | Download reports via `python3 -m http.server`; `find` incl. security uses |
| [06-exit-codes](06-exit-codes/README.md) | Why jobs fail, `\| tee` masking exit codes, `pipefail`, exit codes of every tool in the course |

## Docker

| Lab | Topic |
|---|---|
| [07-docker-basics](07-docker-basics/README.md) | pull/run/exec/ps/top; the `docker run --rm -v $(pwd):/src` scanner pattern decoded |
| [08-docker-volumes](08-docker-volumes/README.md) | Named volumes vs bind mounts, persistence, security of host mounts |
| [09-docker-registry](09-docker-registry/README.md) | Local `registry:2`, tag/push/catalog, authenticated registries, GitLab `CI_REGISTRY_*` |
| [10-docker-networking](10-docker-networking/README.md) | bridge / host / macvlan / none, DNS on user bridges, `--network none` for scanners |
| [11-dockerfile](11-dockerfile/README.md) | 8-step broken→working nginx Dockerfile, CMD vs ENTRYPOINT, PID 1, best-practice version |

## CI/CD platforms

| Lab | Topic |
|---|---|
| [12-gitlab-ci-stages-and-rules](12-gitlab-ci-stages-and-rules/README.md) | Stages; `rules: if/changes/exists`, per-rule `allow_failure`, tag-only manual jobs, `workflow:rules` |
| [13-gitlab-continuous-deployment](13-gitlab-continuous-deployment/README.md) | Build/push to GitLab registry, SSH deploy to prod (fixes the `CI_REGISTRY_PASS` typo) |
| [14-jenkins-pipeline-as-code](14-jenkins-pipeline-as-code/README.md) | Jenkins↔GitLab connection, webhook, declarative Jenkinsfile |
| [15-jenkins-ci](15-jenkins-ci/README.md) | Docker agents, GitLab commit status, parallel stages, archived artifacts |
| [16-jenkins-cd](16-jenkins-cd/README.md) | `docker.build`/`withRegistry` release, `sshagent` deploy |
| [17-github-actions-ci](17-github-actions-ci/README.md) | Workflows, `needs`, `continue-on-error`, artifacts; 2025 runner/action deprecations |
| [18-integrating-tools-volumes](18-integrating-tools-volumes/README.md) | Method for onboarding any tool; redirect inside vs outside the container; image→mount table |

Shared: [common/JENKINS-JOB-SETUP.md](common/JENKINS-JOB-SETUP.md),
[common/GITHUB-REPO-SETUP.md](common/GITHUB-REPO-SETUP.md) (incl. a GitLab ↔ GHA ↔ Jenkins syntax table),
[common/gitlab-ci-base.yml](common/gitlab-ci-base.yml), [common/Jenkinsfile.base](common/Jenkinsfile.base),
[common/github-actions-base.yaml](common/github-actions-base.yaml).

## Software Component Analysis (SCA / OAST)

| Lab | Topic |
|---|---|
| [19-sca-safety](19-sca-safety/README.md) | Safety scan → fix (Django 3.0→4.2.9) → GitLab / Jenkins / GHA |
| [20-sca-retirejs](20-sca-retirejs/README.md) | Retire.js; `npm install` first; `--severity` is a fail threshold, not a filter; `.retireignore.json` |
| [21-sca-dependency-check](21-sca-dependency-check/README.md) | OWASP DC on WebGoat, `--failOnCVSS`, suppression XML, `run-depcheck.sh`, GHA action |
| [22-sca-snyk](22-sca-snyk/README.md) | Snyk auth, out-of-sync lockfile, token as CI secret, GitLab + GHA |
| [23-sca-auditjs](23-sca-auditjs/README.md) | Sonatype OSS Index via AuditJS, nodejs project pipeline |
| [24-sca-bundler-audit](24-sca-bundler-audit/README.md) | Ruby gems in the rails project |
| [25-sca-osv-scanner](25-sca-osv-scanner/README.md) | Fixing direct + transitive deps (`npm list`), offline DB, ignore file, GitLab |
| [26-sca-renovate](26-sca-renovate/README.md) | Automated dependency-update MRs on GitLab (PAT scopes, onboarding, dashboard) |
| [27-sca-semgrep-supply-chain](27-sca-semgrep-supply-chain/README.md) | Reachability analysis: reachable vs undetermined findings |
| [28-sca-trivy](28-sca-trivy/README.md) | `trivy fs/image/config`, severity gates, `.trivyignore` |

## Secrets scanning

| Lab | Topic |
|---|---|
| [29-secrets-trufflehog](29-secrets-trufflehog/README.md) | History scan with verification; detached-HEAD gotcha in CI; GitLab / Jenkins / GHA |
| [30-secrets-detect-secrets](30-secrets-detect-secrets/README.md) | Baseline + audit workflow, pre-commit hook |
| [31-secrets-talisman](31-secrets-talisman/README.md) | Pre-commit/pre-push hooks, `.talismanrc`, why hooks alone aren't enough |
| [32-secrets-semgrep](32-secrets-semgrep/README.md) | `p/secrets`, anonymous (52 rules) vs logged-in (224) |
| [33-secrets-gitleaks](33-secrets-gitleaks/README.md) | GitLab job with report/format/`GIT_DEPTH` fixes, allowlists |

## Static analysis (SAST) and code quality

| Lab | Topic |
|---|---|
| [34-sast-bandit](34-sast-bandit/README.md) | Severity/confidence filters, exit codes, GitLab / Jenkins / GHA, extra-mile threshold gate |
| [35-bandit-false-positive-analysis](35-bandit-false-positive-analysis/README.md) | Reading code to triage; baseline vs `# nosec`; challenge solutions |
| [36-bandit-fixing-issues](36-bandit-fixing-issues/README.md) | `yaml.safe_load`, parameterised SQL for every call site, why B608 keeps flagging f-strings |
| [37-sast-brakeman](37-sast-brakeman/README.md) | Rails SAST, `brakeman.ignore` fingerprints |
| [38-sast-gosec](38-sast-gosec/README.md) | Go SAST, `curl \| sh` risk, rule filtering, GitLab + Jenkins |
| [39-sast-semgrep](39-sast-semgrep/README.md) | `-e` ad-hoc search, metavariables, `--config auto` in GitLab / Jenkins / GHA |
| [40-semgrep-custom-rules](40-semgrep-custom-rules/README.md) | Rule schema, `pattern-not`/`pattern-inside`, **SQLi challenge solution** |
| [41-semgrep-vuln-hunting](41-semgrep-vuln-hunting/README.md) | CSRF, DEBUG misconfig, open redirect, `p/bandit` vs Bandit |
| [42-semgrep-fixing-issues](42-semgrep-fixing-issues/README.md) | Custom rules + `--autofix` on the dvpa app |
| [43-sast-hadolint](43-sast-hadolint/README.md) | Dockerfile lint; course's version-pin fix is broken on alpine 3.15 (how to get real versions) |
| [44-code-quality-pylint](44-code-quality-pylint/README.md) | Message categories, `.pylintrc` (6.37 → 8.41), bitmask exit codes |
| [45-sonarqube](45-sonarqube/README.md) | sonar-scanner, Quality Gates (+ `qualitygate.wait`), custom regex rule, GHA + GitLab |

## Dynamic analysis (DAST)

| Lab | Topic |
|---|---|
| [46-dast-nikto](46-dast-nikto/README.md) | Nikto scan, nikto.conf parameters, plugin challenges |
| [47-dast-sslyze](47-dast-sslyze/README.md) | TLS audit, Mozilla intermediate compliance failure (CBC suites) |
| [48-dast-nmap](48-dast-nmap/README.md) | Port scan, port-drift gate, why 8000 being open is a finding |
| [49-dast-pipeline-nikto-sslyze-nmap](49-dast-pipeline-nikto-sslyze-nmap/README.md) | Build → deploy → DAST pipeline (+ extra-mile SSLyze image) |
| [50-dast-zap](50-dast-zap/README.md) | ZAP baseline, exit codes 0/1/2/3, GitLab / Jenkins / GHA (docker + marketplace) |
| [51-dast-zap-progress-file](51-dast-zap-progress-file/README.md) | Manual FPA with `curl -I`, `WARN-IN_PROGRESS` tracking |
| [52-dast-zap-config-file](52-dast-zap-config-file/README.md) | FAIL / IGNORE / OUTOFSCOPE, tab format, IGNORE vs OUTOFSCOPE |
| [53-dast-dastardly](53-dast-dastardly/README.md) | Burp's CI scanner, JUnit output, ZAP comparison |
| [54-dast-nuclei](54-dast-nuclei/README.md) | Binary vs docker, template subsets, GitLab / Jenkins / GHA |
| [55-nuclei-custom-templates](55-nuclei-custom-templates/README.md) | Vulnerable API on sandbox; header and SQLi templates (+ low-noise variant) |
| [56-katana-crawling](56-katana-crawling/README.md) | Attack surface discovery |
| [57-nuclei-fuzzing](57-nuclei-fuzzing/README.md) | Katana `-f qurl` → Nuclei fuzzing templates on Public Firing Range |
| [58-nuclei-workflows](58-nuclei-workflows/README.md) | Conditional workflows: 2m22s → under 1s for the same findings |

## Infrastructure as Code: Ansible

| Lab | Topic |
|---|---|
| [59-ansible-adhoc](59-ansible-adhoc/README.md) | Inventory, `ansible.cfg` precedence, ping/shell/apt/copy, challenges |
| [60-ansible-playbooks](60-ansible-playbooks/README.md) | Structured playbook deploying django.nv; idempotency and drift detection |
| [61-ansible-conditionals](61-ansible-conditionals/README.md) | `when` + facts, `register`, nginx detect/print/install challenge |
| [62-ansible-hardening](62-ansible-hardening/README.md) | Galaxy roles, `dev-sec.os-hardening` locally, GitLab CI, Jenkins |
| [63-ansible-docker-deploy](63-ansible-docker-deploy/README.md) | Registry push + `docker_*` modules deploy, Python interpreter gotcha |
| [64-ansible-vault](64-ansible-vault/README.md) | Encrypt/view/edit/rekey, `encrypt_string`, vault in CI |

## Infrastructure as Code: Terraform security

| Lab | Topic |
|---|---|
| [65-iac-tflint](65-iac-tflint/README.md) | TF 0.11 quoted-type errors, AWS ruleset, GHA |
| [66-iac-checkov](66-iac-checkov/README.md) | Checks, skip/baseline, `validate` stage (fixes the course's undeclared-stage error), GitLab + Jenkins |
| [67-iac-terrascan](67-iac-terrascan/README.md) | Policies, image entrypoint override, GitLab + GHA |
| [68-iac-tfsec](68-iac-tfsec/README.md) | Impact/resolution output, GitLab + GHA, migration to `trivy config` |
| [69-iac-snyk](69-iac-snyk/README.md) | `snyk iac test` incl. Terraform plan scanning |
| [70-iac-kics](70-iac-kics/README.md) | KICS via docker, HTML report served to the browser |

## Compliance as Code

| Lab | Topic |
|---|---|
| [71-inspec-basics](71-inspec-basics/README.md) | linux-baseline against prod, exit 100, GitLab CI (fixes missing ssh client) |
| [72-inspec-custom-profile](72-inspec-custom-profile/README.md) | Profile scaffolding; **PCI/DSS challenge** (and why it fails on Ubuntu) + CI |
| [73-inspec-shell](73-inspec-shell/README.md) | Interactive resource exploration |
| [74-inspec-resources-and-matchers](74-inspec-resources-and-matchers/README.md) | CIS controls via `command` vs `file`, `eq` vs `cmp` |
| [75-inspec-dependencies](75-inspec-dependencies/README.md) | `depends`, `inspec vendor`, `include_controls` with skip/override |
| [76-inspec-cis-benchmark](76-inspec-cis-benchmark/README.md) | CIS "Configure sudo" profile + prod remediation to 3/3 |
| [77-inspec-asvs](77-inspec-asvs/README.md) | ASVS 14.4 HTTP headers with `http()` resource + nginx fixes |
| [78-inspec-docker](78-inspec-docker/README.md) | CIS Docker benchmark, `-t docker://`, why runtime checks appear |
| [79-inspec-jenkins](79-inspec-jenkins/README.md) | InSpec stage with `sshagent` + `withCredentials` |
| [80-compliance-lynis](80-compliance-lynis/README.md) | Hardening index, report.dat, Lynis vs InSpec |

## Vulnerability management

| Lab | Topic |
|---|---|
| [81-defectdojo-basics](81-defectdojo-basics/README.md) | Data model, product/engagement, API upload (Brakeman/Bandit/ZAP), FP triage |
| [82-defectdojo-gitlab-automation](82-defectdojo-gitlab-automation/README.md) | Upload in `after_script` from GitLab for SAST + DAST |
| [83-defectdojo-jenkins-automation](83-defectdojo-jenkins-automation/README.md) | `withCredentials`, `\|\| true`, ZAP + defectdojo stage challenge |
| [84-defectdojo-github-actions-automation](84-defectdojo-github-actions-automation/README.md) | Repo secrets, `if: always()` upload |

## Capstone

| Lab | Topic |
|---|---|
| [85-capstone-full-devsecops-pipeline](85-capstone-full-devsecops-pipeline/README.md) | One GitLab pipeline: secrets, SAST, SCA, release, deploy, ZAP, Nuclei, hardening, InSpec, DefectDojo; a from-memory self-test; evidence checklist |

## Conventions

- **Do it locally first, then in CI.** Every tool lab follows: install → `--help` →
  scan → save machine-readable output → FP handling → embed with
  `allow_failure` + `artifacts: when: always`.
- **Maturity levels 1–2:** security jobs report but don't block. Block only on
  results you trust (after FP handling).
- **Pipelines are complete files** (base pipeline + the security job), so you
  can paste them straight into GitLab's editor.
- **Tool versions** are pinned to what the course uses so outputs match the
  course text. Each README notes where upstream has since moved on (renamed images,
  deprecated tools, GitHub's 2025 removals).

## Scope notes

- **Course errata are fixed in the files and called out** in each README
  (`CI_REGISTRY_PASS`, the missing `validate` stage, `--suppression x.xml--out`,
  `osv-scanner--config`, `sh -s ---b`, gitleaks report paths, a GHA
  `continue-on-error` on the wrong step, `--rm-v`, missing `docker:dind` image,
  ZAP `-g` overwriting the config, InSpec `prod-server` hostname, the hadolint
  version pins). Search for **"erratum"**.
- **Reconstructions:** `common/upload-results.py` reimplements the course's
  DefectDojo upload snippet (whose source was never shown) with the identical
  CLI. Extra-mile/challenge solutions the course leaves unanswered
  (`bandit_gate.py`, the Semgrep SQLi rule, `Dockerfile.sslyze`,
  `sql-injection-strict.yaml`, remediation scripts) are original and marked as such.
- **Lab-platform dependencies:** GitLab/Jenkins/Dojo/prod hosts and the
  `gitlab.practical-devsecops.training/pdso/*` repos exist only inside the
  course environment. Commands are documented faithfully. Outside the lab,
  substitute your own instances.
- **Hardcoded lab credentials** (`root`/`pdso-training`, `admin`/`admin`) are the
  training environment's defaults and appear only because the course uses them.
  Never reuse that pattern for real systems.
- `sf_secops.pem` in this directory predates these labs and isn't part of them.
