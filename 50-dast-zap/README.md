# Lab 50: DAST with OWASP ZAP Baseline — Local, GitLab, Jenkins, GitHub Actions

## Goal
Run ZAP's **baseline scan** (spider + passive checks only, safe for
production) against the deployed app, then embed it in all three CI systems.

ZAP is OWASP's flagship DAST proxy. It has a daemon mode for CI and a full
REST API/SDK.

## Local

```bash
docker pull softwaresecurityproject/zap-stable:2.13.0
docker run --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py --help
docker run --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t $PROD_URL
# Total of 59 URLs ... PASS: ... (48)
# WARN-NEW: Vulnerable JS Library [10003] x 2  (bootstrap.js, jquery-1.8.3.min.js)
# WARN-NEW: Strict-Transport-Security Header Not Set [10035]
# WARN-NEW: Content Security Policy (CSP) Header Not Set [10038]
# WARN-NEW: Absence of Anti-CSRF Tokens [10202] ...
# FAIL-NEW: 0  WARN-NEW: 17  WARN-INPROG: 0  INFO: 0  IGNORE: 0  PASS: 48

docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm \
  softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t $PROD_URL -J zap-output.json
ls -l zap-output.json
```

| Option | Meaning |
|---|---|
| `-t URL` | target (with protocol) |
| `-J/-x/-r/-w FILE` | JSON / XML / HTML / Markdown report, written under `/zap/wrk` |
| `-c FILE` / `-g FILE` | use / generate the rule config ([lab 52](../52-dast-zap-config-file)) |
| `-p FILE` | progress file ([lab 51](../51-dast-zap-progress-file)) |
| `-m N` | spider minutes (default 1) |
| `-j` | add the AJAX spider (JS-heavy apps) |
| `-a` | include alpha passive rules |
| `-I` | don't return failure on WARN |
| `-l LEVEL`, `-s` | minimum level shown, short output |
| `-n ctx -U user` | authenticated scan via a context file |
| `-z "-config k=v"` | raw ZAP options |

`rw` makes the mount read-write (recommended by the ZAP docs). `-w /zap`
sets the working directory the baseline script needs.

### Exit codes
`0` all PASS, `1` at least one FAIL, `2` WARNs but no FAIL, `3` other error.
The course run exits **2**, so the job "fails" on WARNs. Change
`allow_failure: true` → `false` and see the pipeline stop.

## CI

| System | File | Notes |
|---|---|---|
| GitLab | `ci/gitlab-ci.yml` | `zap-baseline` in **integration** (app must be up), `after_script: docker rmi` frees runner disk |
| Jenkins | `ci/Jenkinsfile` | `-u root` because the Jenkins agent workspace isn't writable by ZAP's default `zap` user |
| GitHub (docker) | `ci/github-actions-docker.yaml` | repo secret `PROD_URL` |
| GitHub (marketplace) | `ci/github-actions-marketplace.yaml` | `zaproxy/action-baseline` opens a **GitHub Issue** with findings (needs `issues: write` and a token) |

Action vs docker run: a marketplace **action** is a provider-maintained
plugin/template. It's less flexible, with nicer integration (issues, SARIF).

## Notes
- Image names: `owasp/zap2docker-stable` → `softwaresecurityproject/zap-stable`
  → **`zaproxy/zap-stable` / `ghcr.io/zaproxy/zaproxy:stable`** (current).
  Course pins 2.13.0 under the middle name.
- Baseline = passive. `zap-full-scan.py` performs **active attacks**. Never
  run that against production without approval.
- ZAP vs others: Nikto is server misconfig and known files, Nuclei is
  template-based CVE and misconfig checks, Dastardly is Burp-quality but a
  fixed config.
- DefectDojo: `ZAP Scan` expects **XML** (`-x zap-output.xml`), not JSON ([lab 81](../81-defectdojo-basics)).
