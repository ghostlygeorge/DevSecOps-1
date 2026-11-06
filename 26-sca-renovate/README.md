# Lab 26: Automated Dependency Updates with Renovate on GitLab

## Goal
Stop fixing vulnerable dependencies by hand. Let **Renovate** open Merge
Requests that bump outdated dependencies (pip, npm, Docker base images,
even CI images), then merge them through normal review.

| Feature | |
|---|---|
| Automation | detects outdated deps and opens MRs |
| Customisation | `renovate.json` rules, schedules, grouping, automerge |
| Ecosystems | npm/Yarn, pip, Maven, Composer, Bundler, Docker, gitlab-ci images, ... |
| Security | fast patch adoption, with optional vulnerability-prioritised MRs |

## Setup

```bash
source ../lab-env.sh
git clone git@${GITLAB_HOST}:root/django-nv.git && cd django-nv
bash ../20-sca-retirejs/install-node.sh
npm install -g renovate        # 2-4 minutes. Ignore the npm "outdated" notice.
renovate -h                    # huge option list: --dry-run, --platform, --token, --autodiscover ...
```

## Errors you'll hit, in order

**1. `ERROR: Git version needs upgrading (detected 2.25.1, minimum 2.33.0)`**
```bash
echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu $(lsb_release -cs) main" >> /etc/apt/sources.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24
apt update && apt install git -y
git --version      # 2.4x
```

**2. `FATAL: You must configure a GitHub token`**: Renovate defaults to
`platform: github`. Point it at GitLab instead (next step).

## GitLab Personal Access Token
`$GITLAB_URL/-/profile/personal_access_tokens` → name `renovatebot`, scopes:

| Scope | Why |
|---|---|
| `api` | create branches, MRs, issues (Dependency Dashboard) |
| `read_api` | read projects/registry |
| `read_repository` | clone over HTTP |
| `write_repository` | push update branches |

## Configure and run

```bash
cp ../26-sca-renovate/renovate-config.js /django-nv/renovate-config.js
labify /django-nv/renovate-config.js && nano /django-nv/renovate-config.js   # paste the token
export RENOVATE_CONFIG_FILE="/django-nv/renovate-config.js"
export NODE_TLS_REJECT_UNAUTHORIZED=0     # lab only: GitLab uses a cert Node doesn't trust
renovate
```

Run 1 output, in order: *Repository started* → *Branch created
renovate/configure* → *Dependency extraction complete* (dockerfile 1,
gitlabci 2, npm 34, pip_requirements 1 → 38 deps) → *Onboarding PR
created* → *Repository finished*.

1. Open `$GITLAB_URL/root/django-nv/-/merge_requests` and **merge** the
   onboarding MR. It adds `renovate.json`.
2. `git pull origin main`
3. `renovate` again. It now creates update MRs: *Update dependency Django
   to v3.2.21* and *Update dependency consolidate to ^0.16.0*, plus a
   **Dependency Dashboard** issue (`/-/issues/1`) with checkboxes for
   manual updates.
4. Merge both MRs, `git pull origin main` (package.json and
   requirements.txt change), and run `renovate`. Nothing left to do.

`WARN: No github.com token ... Skipping release notes retrieval` is
harmless. Renovate fetches changelogs from GitHub and needs a GitHub
token (`GITHUB_COM_TOKEN`) for that.

## Why Renovate needs a Git platform
Version control (each update is a branch + commit, easy to revert), review
(MRs, CI runs on the update before merge), workflow (async alerts, no manual
checking), and access to the dependency files themselves.

## Running it properly
- **In Docker** instead of installing Node + new git:
  `docker run --rm -e RENOVATE_TOKEN -e RENOVATE_PLATFORM=gitlab -e RENOVATE_ENDPOINT=$GITLAB_URL/api/v4 renovate/renovate root/django-nv`
- **Scheduled in CI**: `gitlab-ci-renovate.yml` + a pipeline schedule. That's the real-world pattern.
- `renovate.json.example`: security-oriented repo config (vulnerability
  alerts, automerge patches, pin Docker digests).

## Notes
- `NODE_TLS_REJECT_UNAUTHORIZED=0` disables **all** TLS verification for
  the process. Never use it outside a lab. Use `NODE_EXTRA_CA_CERTS=/path/ca.pem` instead.
- Don't leave the token in `renovate-config.js` in a repo. Use `RENOVATE_TOKEN`.
- A Renovate MR that bumps Django 3.0 → 3.2.21 still needs the app's tests
  to pass before merging. Automation proposes, CI and humans approve.
