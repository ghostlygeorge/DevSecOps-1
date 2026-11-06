# Lab 30: Secrets Scanning with detect-secrets (Yelp)

## Goal
Use **detect-secrets**, which is built around a **baseline**: scan once,
audit/mark findings as real or false, then only alert on *new* secrets.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install detect-secrets==1.4.0
detect-secrets --help        # scan | audit
```

## Scan

```bash
detect-secrets scan .                      # JSON to stdout: plugins_used, filters_used, results{file:[...]}
cd .. && detect-secrets scan /webapp       # same result: path = current dir (.) or an explicit dir
cd /webapp
detect-secrets scan . > secrets-output.json      # this file IS the baseline (.secrets.baseline by convention)
jq '.results | to_entries[] | {file: .key, n: (.value|length), types: [.value[].type]}' secrets-output.json
```

Each result stores a **hashed_secret** (SHA-1), never the secret itself,
so the baseline is safe to commit.

## Audit (mark TP / FP)

```bash
detect-secrets audit secrets-output.json          # interactive: y = real secret, n = false positive, s = skip, q = quit
echo "q\n" | detect-secrets audit secrets-output.json     # course: just peek at the first item and quit
```

Answers are written back into the baseline as `"is_secret": true|false`.
Later scans with `--baseline` skip known items:

```bash
detect-secrets scan --baseline .secrets.baseline   # updates it in place, adds only NEW findings
detect-secrets audit --report .secrets.baseline    # summary report (1.x)
```

## Pre-commit hook (where it shines)

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

The hook exits 1 if a commit adds a secret that isn't in the baseline.

## Compared with TruffleHog
| | TruffleHog | detect-secrets |
|---|---|---|
| History | yes, every commit | no, current files |
| Verification | live API checks | none |
| FP workflow | external | built-in baseline + audit |
| Speed/noise | heavier | lighter, enterprise "prevent new secrets" model |

The course's "did you notice it's much more efficient than TruffleHog?"
refers to this: it's fast, and the baseline makes the result set manageable.

## Notes
- Inline allow-listing: `password = "x"  # pragma: allowlist secret`.
- Filters out common false positives with heuristics (`--exclude-files`,
  `--exclude-lines`, and entropy limits like `--base64-limit`).
