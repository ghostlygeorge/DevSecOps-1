# Lab 22: SCA with Snyk (commercial, free tier)

## Goal
Use Snyk's CLI to find vulnerable dependencies, work through its
real-world setup errors, and embed it with a **secret token** in GitLab CI
and GitHub Actions.

> Sign up for a **free personal** Snyk account. Never use your company's
> Snyk token in labs.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
wget -O /usr/local/bin/snyk https://github.com/snyk/cli/releases/download/v1.984.0/snyk-linux
chmod +x /usr/local/bin/snyk
snyk --help       # auth, test, monitor, container, iac, code, ignore, policy...
```

## Errors you'll hit, in order (and the fixes)

| Command | Error | Fix |
|---|---|---|
| `snyk test --json .` | `MissingApiTokenError` | Sign up → <https://app.snyk.io/account> → copy token → `snyk auth TOKEN` or `export SNYK_TOKEN=TOKEN` |
| `snyk test --json .` | `Missing node_modules folder ... run 'npm install'` | Snyk tests the *installed* npm tree (unlike Safety, which reads requirements.txt). `bash ../20-sca-retirejs/install-node.sh && npm install` |
| `snyk test --json . > output.json` | `Dependency bcrypt-nodejs was not found in package-lock.json ... out of sync` | `snyk test --strict-out-of-sync=false --json . > output.json` |

```bash
snyk auth YOUR_API_TOKEN_HERE
npm install
snyk test --strict-out-of-sync=false --json . > output.json
jq '.uniqueCount, .summary' output.json
snyk monitor     # snapshot to the Snyk dashboard, alerts on NEW vulns later
```

**Why `npm install` for Snyk but not Safety?** npm's lockfile/`node_modules`
holds the resolved transitive tree. `package.json` has ranges (`^1.2.0`).
Snyk wants the real resolved versions, which also explains the
out-of-sync error when package.json and the lock disagree.

## GitLab CI
1. `$GITLAB_URL/root/django-nv/-/settings/ci_cd` → Variables → `SNYK_TOKEN`
   = your token, **Protected** on (and Masked).
2. Paste `ci/gitlab-ci.yml`. `oast-snyk` runs in the **build** stage on
   `node:alpine3.10` with Snyk's **alpine** binary (glibc vs musl: the
   `snyk-linux` binary won't run on Alpine).

The job fails with exit 1 (vulnerabilities found), and `allow_failure`
lets the pipeline continue.

> Protected variables are only injected on **protected branches/tags**.
> If `snyk auth` says the token is empty on a feature branch, that's why.

## GitHub Actions
Repo → Settings → Secrets → `SNYK_TOKEN`, then `ci/github-actions.yaml`.
The course uses `actions/setup-go` and Node 10. Neither is needed or
available on current runners.

## Notes
- `snyk ignore --id=SNYK-JS-XXX --reason="FP" --expiry=2026-12-31` writes a
  `.snyk` policy file. Commit it: that's Snyk's FP mechanism.
- `--severity-threshold=high` changes the exit code threshold.
- The same CLI does `snyk iac test` ([lab 69](../69-iac-snyk)),
  `snyk container test`, and `snyk code test` (SAST).
