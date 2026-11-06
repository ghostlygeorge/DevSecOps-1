# Lab 43: Dockerfile Linting with Hadolint

## Goal
Lint a Dockerfile for best-practice and security issues with **Hadolint**
(parses the Dockerfile into an AST and runs ShellCheck on `RUN` lines),
and fix the finding.

## Install

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
wget https://github.com/hadolint/hadolint/releases/download/v1.18.0/hadolint-Linux-x86_64
mv hadolint-Linux-x86_64 /usr/local/bin/hadolint && chmod +x /usr/local/bin/hadolint
hadolint --help      # -f tty|json|checkstyle|codeclimate|codacy  --ignore RULE  --trusted-registry REG  -c config
# or with no install:  docker run --rm -i hadolint/hadolint < Dockerfile
```

## Lint

```bash
hadolint Dockerfile
# Dockerfile:9 DL3018 Pin versions in apk add. Instead of `apk add <package>` use `apk add <package>=<version>`
cat -n Dockerfile          # -n shows line numbers
```

**DL3018**: unpinned `apk add` means every rebuild can pull different
package versions, so builds aren't reproducible and a bad package update
lands silently.

## Fix

```dockerfile
RUN apk add --no-cache gawk=<ver> sed=<ver> bash=<ver> grep=<ver> bc=<ver> coreutils=<ver>
```

> **Course erratum:** the course "fixed" Dockerfile pins
> `gawk=5.0.1-r0 sed=4.7-r0 bash=5.0.11-r1 ...`, which are **Alpine 3.10**
> versions, on a `python:3-alpine3.15` base. Hadolint passes (it doesn't
> check that versions exist) but `docker build` fails with
> `unable to select packages`. It also swaps in a different Dockerfile
> (`reset_db.sh`, `run_app_docker.sh`). That's also why the course's line
> number (9) doesn't match `cat -n` (11). Get real versions for the actual
> base image:
>
> ```bash
> docker run --rm python:3-alpine3.15 sh -c 'apk update >/dev/null; for p in gawk sed bash grep bc coreutils; do apk policy $p | sed -n 2p | tr -d " :" | sed "s/^/$p=/"; done'
> ```
>
> Pin with `~=` (`bash~=5.1`) to allow patch updates.

```bash
hadolint Dockerfile        # no output = no issues
```

## Common rules
| Rule | Issue |
|---|---|
| DL3006 / DL3007 | untagged image / using `:latest` |
| DL3008 / DL3018 / DL3013 | unpinned apt / apk / pip packages |
| DL3009 | apt lists not deleted |
| DL3002 | last `USER` is root |
| DL3020 | `ADD` used for local files instead of `COPY` |
| DL3025 | `CMD`/`ENTRYPOINT` not in JSON (exec) form |
| DL4006 | `RUN` with a pipe and no `set -o pipefail` |
| SCxxxx | ShellCheck issues inside `RUN` |

## Config / CI
`hadolint.yaml` (save as `.hadolint.yaml`): failure threshold, ignored
rules, trusted registries. `gitlab-ci-hadolint.yml`: runs only on
Dockerfile changes using `rules: changes`.
