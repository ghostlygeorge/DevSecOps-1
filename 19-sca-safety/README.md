# Lab 19: SCA with Safety — Scan, Fix, and Embed (GitLab / Jenkins / GitHub Actions)

## Goal
Find known-vulnerable Python dependencies with **Safety**, fix them by
upgrading, and run the scan in all three CI systems without blocking the
build.

Safety checks installed or declared dependencies against the open Safety DB
(or pyup.io's commercial API with `--key`/`SAFETY_API_KEY`).

## 1. Scan locally

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install safety==2.3.5
safety check --help
safety check -r requirements.txt --json | tee safety-output.json
```

| Flag | Meaning |
|---|---|
| `-r FILE` | requirements file to scan (repeatable) |
| `--json` / `--output json` | machine-readable output |
| `--full-report` | include advisories |
| `-i ID` | ignore a vulnerability ID (the FP mechanism) |
| `--policy-file` | `.safety-policy.yml` with ignores/severity thresholds |
| `--continue-on-error` | exit 0 even with findings (default exit code is 64) |
| `--save-json PATH` | write JSON **and** keep the screen report |

Expected: `"packages_found": 1, "vulnerabilities_found": 26` (numbers drift
over time), all in `Django==3.0`.

Useful jq:
```bash
jq '.report_meta.vulnerabilities_found' safety-output.json
jq -r '.vulnerabilities[] | "\(.package_name) \(.analyzed_version) \(.CVE)"' safety-output.json
```

## 2. Fix

```bash
cat requirements.txt            # Django==3.0
cat > requirements.txt <<EOF
Django==4.2.9
EOF
safety check -r requirements.txt --json | tee safety-output.json   # vulnerabilities_found: 0
```

Check PyPI release history (<https://pypi.org/project/Django/#history>)
and the release notes, and **talk to the developers**. A major upgrade
(3.0 → 4.2) can break the app. Re-run the app's tests after any upgrade.
Target: no critical/high findings.

## 3. Embed in CI

| System | File | Allow failure | Report |
|---|---|---|---|
| GitLab | `ci/gitlab-ci.yml` | `allow_failure: true` | `artifacts: when: always` |
| Jenkins | `ci/Jenkinsfile` | `catchError(buildResult:'SUCCESS', stageResult:'UNSTABLE')` | `archiveArtifacts` in `post { always }` |
| GitHub | `ci/github-actions.yaml` | `continue-on-error: true` | `upload-artifact` + `if: always()` |

Jenkins setup: [common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md).
GitHub setup: [common/GITHUB-REPO-SETUP.md](../common/GITHUB-REPO-SETUP.md).

**Which stage?** Up to 95% of a typical codebase is third-party code, so
run SCA early, before SAST. The course puts it in `test` (GitLab) or a
dedicated `oast` stage (Jenkins challenge: "rename test stage to oast").

## Notes
- **The `| tee` gotcha**: the GitLab/Jenkins jobs here never actually fail,
  because `tee` returns 0 (see [lab 06](../06-exit-codes)). They report but
  can't gate. For a gate, use `set -o pipefail` or `--save-json`.
- `-v $(pwd):/src`: the volume is how Safety sees `requirements.txt`
  ([lab 18](../18-integrating-tools-volumes)).
- Safety 3.x replaced `check` with `scan` and requires a login. Pin `2.3.5`
  for this course.
- OAST is the course's name for SCA ("Open-source Analysis Security Testing").
