# Lab 33: Secrets Scanning with Gitleaks in GitLab CI

## Goal
Add **Gitleaks** to the django.nv pipeline, save a report artifact, and
make it non-blocking.

## Run locally first

```bash
git clone git@${GITLAB_HOST}:root/django-nv.git && cd django-nv
docker run --rm -v $(pwd):/path -w /path zricethezav/gitleaks detect --source . -v           # -v prints each finding
docker run --rm -v $(pwd):/path -w /path zricethezav/gitleaks detect --source . --no-git     # files only, no history
docker run --rm -v $(pwd):/path -w /path zricethezav/gitleaks detect --source . --report-format json --report-path gitleaks-output.json
echo $?    # 1 = leaks found
jq '.[] | {RuleID, File, StartLine, Commit}' gitleaks-output.json
```

## GitLab CI
Paste `ci/gitlab-ci.yml` (base pipeline + `gitleaks` job in the build stage).

**Course errata fixed in `ci/gitlab-ci.yml`:**
| Course | Problem | Fix |
|---|---|---|
| `detect .` | positional path is ignored; works only because source defaults to CWD | `detect --source .` |
| `--report-path gitleaks-output.txt` with `artifacts: gitleaks-output.json` | artifact path never exists → "no matching files" | same `.json` name in both places |
| no `--report-format` | the format is guessed from the extension in newer versions, JSON in older ones | explicit `--report-format json` |
| default `GIT_DEPTH` (20) | `detect` scans git log, so older leaked commits are missed | `GIT_DEPTH: 0` |

**Exit codes**: 1 when leaks are found. Use `--exit-code N` to change it,
then gate with `allow_failure` or `allow_failure: {exit_codes: [N]}`.

## False positives
`gitleaks.toml.example`: extend the default rules and allowlist by path,
regex, or commit. Or list individual finding fingerprints in
`.gitleaksignore`. Inline: `# gitleaks:allow` on the line.

## Notes
- Gitleaks v8.19+ renamed the commands: `gitleaks git` (history) and
  `gitleaks dir` (files). `detect` still works but is deprecated.
- `--user $(id -u):$(id -g)` lets the job clean up the report file. Note
  gitleaks also needs git's `safe.directory` when the repo owner differs from
  the user. If you see `dubious ownership`, drop `--user` or add
  `-e GIT_CONFIG_PARAMETERS="'safe.directory=*'"`.
- DefectDojo scanner name: `Gitleaks Scan`.
