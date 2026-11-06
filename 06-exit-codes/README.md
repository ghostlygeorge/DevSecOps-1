# Lab 06: Exit Codes — Why Security Jobs "Fail"

## Goal
The course repeatedly says "the job failed because of a non-zero exit
code, see *Working with Exit Code*". This lab is that reference: how CI
systems interpret exit codes, and what each tool in this course returns.

## The rule
- `0` = success. Any **non-zero** = failure, and CI marks the job/stage failed.
- `echo $?` prints the exit code of the **last** command.
- A DevSecOps-friendly tool returns non-zero **when it finds issues**.
  That's a feature: it lets the pipeline act as a gate.

```bash
true;  echo $?    # 0
false; echo $?    # 1
ls /nope; echo $? # 2
```

## Pipes hide exit codes (the #1 surprise in this course)

```bash
bandit -r . -f json | tee out.json ; echo $?     # 0!  exit code of `tee`, not bandit
set -o pipefail
bandit -r . -f json | tee out.json ; echo $?     # 1   bandit's code propagates
```

So these course jobs **never fail** even when issues are found:
`docker run ... safety check ... | tee oast-results.json`,
`checkov ... | tee checkov-output.json`. GitLab's default shell has no
`pipefail`. If you want the job to gate, add `set -o pipefail` or write
the report with the tool's own `-o/--output` flag instead of `tee`.

Conversely `cmd || true` (used in the DefectDojo Jenkins lab) forces 0 so the
next command still runs. `after_script` in GitLab always runs regardless.

## Tool exit-code reference

| Tool | Findings → | Notes / how to change |
|---|---|---|
| bandit | `1` | `--exit-zero` → always 0. `2` = usage error. |
| safety 2.x `check` | `64` | `--continue-on-error` → 0 |
| retire.js | `13` | `--exitwith N` changes it. `--severity X` sets the threshold for **failing**; it doesn't filter the report. |
| OWASP dependency-check | `0` | `--failOnCVSS N` → non-zero (15 in the course run) when any CVSS ≥ N |
| snyk test / iac | `1` | `2` = failure, `3` = no supported project |
| auditjs, bundle-audit, npm audit, osv-scanner | `1` | |
| trufflehog v3 | `0` | `--fail` → `183` on results |
| gitleaks | `1` | `--exit-code N` |
| detect-secrets scan | `0` | it writes a baseline. The `detect-secrets-hook` returns 1. |
| talisman | `1` | blocks the commit/push |
| brakeman | `3` | `-z/--exit-on-warn` is default. `--no-exit-on-warn` → 0. `7` = errors. |
| gosec | `1` | `-no-fail` → 0 |
| semgrep scan | `0` | `--error` → 1 on findings |
| semgrep ci | `1` | only on *blocking* findings |
| hadolint | `1` | `--failure-threshold error` to ignore warnings/info |
| pylint | bitmask | 1 fatal, 2 error, 4 warning, 8 refactor, 16 convention, 32 usage. `--exit-zero`, `--fail-under` |
| sonar-scanner | `0` | `-Dsonar.qualitygate.wait=true` → 1 when the gate fails |
| trivy | `0` | `--exit-code 1` (+ `--severity HIGH,CRITICAL`) |
| tflint | `2` | issues found. `1` = error. `--force` → 0 |
| tfsec | `1` | `-s/--soft-fail` → 0 |
| checkov | `1` | `--soft-fail`, `--soft-fail-on`, `--hard-fail-on` |
| terrascan | `3` | violations found. `1` = error |
| kics | `60/50/40/30/20` | exit code = highest severity found (critical/high/medium/low/info). `--ignore-on-exit results` → 0 |
| zap-baseline.py | `0/1/2/3` | 1 = any FAIL, 2 = WARN only, 3 = error. `-I` = don't fail on WARN |
| dastardly | `1` | fails on any issue above INFO |
| nuclei | `0` | even with findings |
| nikto, nmap, sslyze | `0` | report-only tools |
| inspec exec | `100` | ≥1 control failed. `101` = only skips. `0` = all passed |
| ansible-playbook | `2` | failed host(s). `4` = unreachable |
| lynis | `0` | `--error-on-warnings` changes it |

## Turning it into policy

```yaml
# Maturity level 1-2: report, don't block
sast:
  script: [bandit -r . -f json -o bandit.json]
  allow_failure: true

# Maturity level 3-4: block only on what you trust
sast-gate:
  script:
    - bandit -r . -lll -iii          # HIGH severity AND HIGH confidence only
  allow_failure: false

# GitLab can also be selective:
  allow_failure:
    exit_codes: [2]                   # tolerate WARN, fail on FAIL (zap-baseline)
```

## Try it

```bash
bash try-exit-codes.sh
```
