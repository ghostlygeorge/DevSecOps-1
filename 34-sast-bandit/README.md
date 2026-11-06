# Lab 34: SAST with Bandit — Scan and Embed (GitLab / Jenkins / GitHub Actions)

## Goal
Run Bandit, the Python SAST tool, filter by severity and confidence,
understand its exit codes, and embed it non-blocking in all three CI
systems.

Bandit parses each file into an **AST** and runs plugins against the nodes
(originally from OpenStack Security, now under PyCQA).

## Local

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install bandit==1.7.4
bandit --help
bandit -r . -f json | tee bandit-output.json     # 3 issues: 1 high, 1 medium, 1 low
jq '.metrics._totals' bandit-output.json
```

### Severity / confidence filters

| Flag | Shows |
|---|---|
| `-l` / `--severity-level low` | LOW and above |
| `-ll` / `--severity-level medium` | MEDIUM and above |
| `-lll` / `--severity-level high` | HIGH only |
| `-i`, `-ii`, `-iii` / `--confidence-level` | same scale for confidence |

```bash
bandit -r . -l ; bandit -r . -ll ; bandit -r . -lll
bandit -r . -lll -iii      # the classic "safe to block on" gate: high sev AND high confidence
```

Also: `-x tests,venv` to exclude paths, `-s B101` to skip test IDs,
`-t` to run only some, `--exit-zero`, `-b baseline.json` ([lab 35](../35-bandit-false-positive-analysis)),
and `-c .bandit` / `--ini` for config.

### Exit codes
| Code | Meaning |
|---|---|
| 0 | no issues at/above the chosen level |
| 1 | issues found |
| 2 | error (bad argument, unparsable code) |

## CI

| File | Notes |
|---|---|
| `ci/gitlab-ci.yml` | `sast` job in the **build** stage (SAST needs no build), `allow_failure`, artifact |
| `ci/Jenkinsfile` | `sast` stage with `catchError` + `archiveArtifacts` in `post { always }` |
| `ci/github-actions.yaml` | `continue-on-error` on the scan **step**, `upload-artifact` with `if: always()` |

Bandit writes the report itself (`-o /src/bandit-output.json`), so the
job **does** fail with exit 1, unlike the `| tee` jobs. That's why
`allow_failure`/`catchError` matter here.

**Docker flags:** `-v $(pwd):/src` mounts the runner's CWD (on Windows it
could be `c:\Users\me\code:/src`). `--rm` cleans up the container. `--user
$(id -u):$(id -g)`: remove it and the report becomes root-owned. On shell
executors the next job's `git clean` then fails with `permission denied`.
(See "running a docker container as a non-root user".)

## Extra mile (no official solution)
Fail only when you hit **3 high, 1 low, 1 medium**, with coloured output
(red/blue/orange):

```bash
bandit -r . -f json -o bandit-output.json --exit-zero
python3 ../34-sast-bandit/bandit_gate.py bandit-output.json --high 3 --medium 1 --low 1
docker build -t bandit-gate -f ../34-sast-bandit/Dockerfile.gate ../34-sast-bandit
docker run --rm -v $(pwd):/src bandit-gate
```

This is the maturity level 3–4 idea: custom criteria for failing a build,
which is only possible once FPs are handled programmatically (baseline, not
`# nosec`).
