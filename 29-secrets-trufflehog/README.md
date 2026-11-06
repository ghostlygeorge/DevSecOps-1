# Lab 29: Secrets Scanning with TruffleHog (local, GitLab, Jenkins, GitHub)

## Goal
Find credentials committed anywhere in a repo's **history** with
TruffleHog v3, which also **verifies** whether a secret is live. Then run
it in CI and understand why a naive CI integration finds nothing.

## Install

```bash
wget https://github.com/trufflesecurity/trufflehog/releases/download/v3.28.0/trufflehog_3.28.0_linux_amd64.tar.gz
tar -xvf trufflehog_3.28.0_linux_amd64.tar.gz && chmod +x trufflehog && mv trufflehog /usr/local/bin/
trufflehog --help
```

| Subcommand / flag | Meaning |
|---|---|
| `git <uri>` | scan every commit/branch of a repo (no clone needed) |
| `filesystem --directory=DIR` | scan files on disk only (no history) |
| `github`, `gitlab --token`, `s3`, `syslog`, `circleci` | other sources |
| `-j/--json` | JSON Lines (one finding per line) |
| `--only-verified` | only secrets confirmed live against the provider's API |
| `--no-verification` | don't call provider APIs (offline/no exfil) |
| `--fail` | exit **183** when results are found |

## Scan the repo history

```bash
source ../lab-env.sh
trufflehog git http://gitlab-ce-${LAB_ID}.lab.practical-devsecops.training/root/django-nv.git --json
trufflehog git git@${GITLAB_HOST}:root/django-nv.git --json | tee secret.json     # SSH (box key is in GitLab)
cat secret.json | jq
jq -r 'select(.DetectorName) | "\(.DetectorName) verified=\(.Verified) \(.SourceMetadata.Data.Git.file):\(.SourceMetadata.Data.Git.line)"' secret.json
```

Findings: **AWS** key in `taskManager/settings.py:19` with **Verified: true**
(it's a canarytokens.com key, so using it alerts its owner), and a **Slack**
token on line 22, unverified. The last JSON line is a log summary
(`verified_secrets: 1, unverified_secrets: 1`), not a finding.

## GitLab CI — why the first attempt is empty
`ci/gitlab-ci-debug-detached-head.yml` reproduces the course's debugging:
`git status` in the job prints `HEAD detached at c4560d9`. CI runners check
out a specific **commit**, not a branch, so branch-based git scanning sees
nothing. Fix: use **`filesystem`** mode, which scans whatever the runner
checked out (`ci/gitlab-ci.yml`).

## Jenkins
Same detached-HEAD problem. The course re-checks-out the branch with the
`git` step (credentials `gitlab-auth`) before scanning. See `ci/Jenkinsfile`
(replace `LABID`). The artifact is archived in the stage's `post { always }`.

## GitHub Actions
`ci/github-actions.yaml`. Disable **Push protection** on public repos
first, or GitHub blocks the push of django.nv's fake keys
([common/GITHUB-REPO-SETUP.md](../common/GITHUB-REPO-SETUP.md)).

> **Course erratum:** the final GHA YAML has `docker run --rm-v` (missing
> space), which is an unknown flag and fails. Fixed here.

## Notes
- **Filesystem vs git mode**: filesystem only sees the current files. A
  key committed then deleted is invisible to it but still in history and
  still leaked. Scan history at least once (`trufflehog git` with full
  clone, or in CI set `GIT_DEPTH: 0` and use
  `git file:///src --since-commit ...`).
- The real fix for a found secret is to **rotate it**. Deleting the commit
  doesn't help, since it's already been cloned. See <https://howtorotate.com>.
- DefectDojo scanner: `Trufflehog Scan` (v3 JSON).
