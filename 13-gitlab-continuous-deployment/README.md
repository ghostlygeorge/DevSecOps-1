# Lab 13: Continuous Deployment with GitLab CI

## Goal
Build the django.nv image, push it to the GitLab registry, and SSH-deploy
it to the production machine from the pipeline. Every DAST lab needs this
running app as its target.

## Setup: CI/CD variables
`$GITLAB_URL/root/django-nv/-/settings/ci_cd` → **Variables → Expand → Add variable**

| Key | Value |
|---|---|
| `PROD_USERNAME` | `root` |
| `PROD_HOSTNAME` | `prod-<id>` |
| `PROD_SSH_PRIVKEY` | prod's private key (below). Tick **Protected**. |

```bash
ssh root@$PROD_HOST
more /root/.ssh/id_rsa        # copy from -----BEGIN RSA PRIVATE KEY----- to -----END RSA PRIVATE KEY-----
exit
```

## Files
- `gitlab-ci.yml`: build → test → **release** (docker build/push) → integration → **prod** (ssh deploy).

## Running
Paste into `.gitlab-ci.yml` → commit → `$GITLAB_URL/root/django-nv/pipelines`.
On success the Task Manager is live at `$PROD_URL` (login `admin`/`admin`).

```bash
ssh root@$PROD_HOST docker ps     # django.nv  0.0.0.0:8000->8000/tcp
```

## How the deploy works
1. `release` builds `$CI_REGISTRY_IMAGE` (= `registry/root/django-nv`) and pushes it.
2. `prod` runs in a tiny `kroniak/ssh-client` image, writes the key, starts
   `ssh-agent`, pins prod's host key, and sends a heredoc of commands over SSH.
3. On prod: log in to the registry, remove the old container, run the new one.

## Gotchas / course errata
- The course's first `prod` snippet uses `${CI_REGISTRY_PASS}`. That
  variable **doesn't exist**. The correct predefined variable is
  `$CI_REGISTRY_PASSWORD` (fixed here). Login silently fails with the typo,
  and the pull then fails with `unauthorized`.
- `docker login -p` on prod puts the job token in prod's process list and
  `~/.docker/config.json`. Prefer `--password-stdin`.
  `$CI_REGISTRY_PASSWORD` is a **job token** that expires when the job ends,
  so prod can't pull later (e.g. after a reboot) with it. Use a deploy
  token for long-lived pulls.
- `only: [main]` keeps feature branches from deploying.
- The deployed image is `:latest`. Lab 49 improves this with
  `$CI_COMMIT_SHA` tags for traceability.
- SSH issues: see lab 03. Usually it's a truncated key or Windows `\r`
  (hence `tr -d '\r'`).

This is Continuous **Deployment**: every green `main` pipeline ships. With
`when: manual` on `prod` it becomes Continuous **Delivery**.
