# Lab 32: Secrets Scanning with Semgrep (`p/secrets`)

## Goal
Use Semgrep's curated secrets ruleset, and see how logging in unlocks more
(Pro) rules.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install semgrep==1.30.0
semgrep --help
pip3 install --upgrade requests     # if every command warns about urllib3/chardet versions
```

## Scan: anonymous vs logged in

```bash
semgrep --config "p/secrets"
# Scanning 148 files ... with 52 Code rules
# taskManager/settings.py
#   detected-aws-access-key-id-value  19: AWS_ACCESS_KEY_ID = 'AKIAYVP4CIPPERUVIFXG'
#   detected-aws-secret-access-key    20: AWS_SECRET_ACCESS_KEY = 'Zt2U1h267e...'
# Ran 52 rules on 140 files: 2 findings.

semgrep login           # personal GitHub/GitLab account, never corporate
semgrep --config "p/secrets"
# ... with 224 Code rules (172 Pro rules) ... Ran 224 rules on 140 files: 2 findings.
```

**Why 52 vs 224?** The registry pack lists 224 rules, but only the
community subset runs anonymously. Logging in adds the Pro rules. Here
it's the same 2 findings, but on other codebases the Pro rules catch more.
Rule counts grow over time.

Metrics note: using registry configs (`p/...`) sends pseudonymous rule
metrics. Add `--metrics=off` to disable that. Local `--config rules.yml`
never sends metrics.

## Save results

```bash
semgrep --config "p/secrets" --json -o semgrep-secrets.json
semgrep --config "p/secrets" --gitlab-secrets -o gl-secret-detection-report.json   # GitLab Security dashboard format
```

## Notes
- Semgrep only scans **git-tracked** files (`Scan was limited to files tracked by git`)
  and honours `.semgrepignore`. Untracked secrets won't show up.
- Semgrep does pattern/regex matching on **current** files only. Combine it
  with a history scanner (TruffleHog/Gitleaks).
- The fix: never hardcode `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`.
  Read them from the environment or a secret manager (Vault, AWS Secrets
  Manager), and **rotate** the leaked keys.
