# Lab 39: SAST with Semgrep — Basics and CI (GitLab / Jenkins / GitHub Actions)

## Goal
Use Semgrep's code-like patterns for ad-hoc code search, then run the
registry rules in all three CI systems.

Semgrep rules look like the code you're searching for. There's no AST
walking or regex wrestling to write by hand.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install semgrep==1.30.0
semgrep --help
pip3 install --upgrade requests          # if every command warns about urllib3/chardet
```

| Argument category | Examples |
|---|---|
| positional | target file/dir (`.`) |
| optional | `--include`, `--exclude`, `--lang`, `--max-lines-per-finding` |
| config | `--config auto`, `--config p/bandit`, `-f rules.yml`, `-e PATTERN` |
| output | `--json`, `--sarif`, `--gitlab-sast`, `-o FILE` |

## Ad-hoc search with `-e`

```bash
semgrep --lang python -e "os.system(...)" .                   # taskManager/misc.py:33 "mv " + ...
semgrep --lang python -e "os.system(...)" . --json | jq '.results[] | {path, line: .start.line}'
semgrep --lang python -e "DEBUG = True" --include settings.py .   # taskManager/settings.py:28
```

(`-e` = `--pattern`, which requires `--lang`. `...` = ellipsis: any args/statements.)

## Challenges

```bash
semgrep --lang python -e '$X = $Y' .              # #1 every variable assignment
semgrep --lang python -e '$FUNC(request)' .       # #2 every call that takes `request` as an argument
```

`$X` is a **metavariable**: it matches any expression and binds it, so
`$X == $X` only matches identical sides.

## CI

| File | Notes |
|---|---|
| `ci/gitlab-ci.yml` | `semgrep` job in **build** with `--config auto` |
| `ci/Jenkinsfile` | `sast` stage, `catchError`, archive |
| `ci/github-actions.yaml` | `continue-on-error` on the **scan step** |

> **Course erratum (GHA):** the course places `continue-on-error: true` on
> the `upload-artifact` step, not the `docker run` step. A failing scan
> then still fails the job. Fixed here.

`--config auto` downloads rules matched to the detected languages and
**sends metrics** to semgrep.dev. For air-gapped/reproducible CI, commit
your rules and use `--config ./rules/` (+ `--metrics=off`). Semgrep scan
exits 0 even with findings unless you add `--error`.

## Notes
- The image was renamed `returntocorp/semgrep` → `semgrep/semgrep`.
- Semgrep scans git-tracked files only, honouring `.semgrepignore`.
