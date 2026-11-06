# Lab 31: Preventing Secret Commits with Talisman (git hooks)

## Goal
Install **Talisman** as a git pre-commit/pre-push hook that blocks
secrets **before they leave the developer's machine**, and understand why
hooks alone are not enough.

## Why hooks are not enough
- Hooks live only on the developer's workstation.
- An admin user can just disable them (`git commit --no-verify`, delete the hook).
- No way to enforce them org-wide.

So **also** run secret scanning in CI ([labs 29](../29-secrets-trufflehog),
[33](../33-secrets-gitleaks)): that gives enforcement **and** visibility.
Hooks give fast feedback. Use both.

Git hooks are scripts run on git events (commit, push, rebase, ...). Talisman supports:

| Hook | Runs | Trade-off |
|---|---|---|
| `pre-commit` | before each commit | earliest feedback, but runs often |
| `pre-push` | before push | less friction, but the secret is already in local history |

## Install (pre-commit)

```bash
curl --silent https://raw.githubusercontent.com/thoughtworks/talisman/master/global_install_scripts/install.bash > /tmp/install_talisman.bash \
  && /bin/bash /tmp/install_talisman.bash pre-commit
#  -> choose 1) Set TALISMAN_HOME in ~/.bashrc
#  -> interactive mode? n
#  -> sets up a git TEMPLATE dir (~/.git-template) so every new clone/init gets the hook
#  -> searches /root for existing repos to add the hook to
```

(`... install.bash pre-push` installs the pre-push variant.)

## Watch it block a key

```bash
source ../lab-env.sh
git clone http://gitlab-ce-${LAB_ID}.lab.practical-devsecops.training/root/django-nv.git webapp && cd webapp
cp ~/.ssh/id_rsa .
git add id_rsa
git commit -m "Add private key"
# *** Please tell me who you are.  -> set identity first:
git config --global user.email "student@pdevsecops.com"
git config --global user.name  "DevSecOps Student"
git commit -m "Add private key"
# Talisman Report:
# | id_rsa | The file name "id_rsa" failed checks against the pattern ^.+_rsa$ | high |
# | id_rsa | Expected file to not to contain base64 encoded texts such as: MIIEpAIB... | high |
# | id_rsa | Potential secret pattern : -----BEGIN RSA PRIVATE KEY----- | high |
```

Detectors used: **filename** patterns, **base64/hex entropy**, **secret
patterns**, and file size.

### Intentionally committing (test fixtures)
```bash
talisman --checksum id_rsa         # prints a .talismanrc snippet
# add it to .talismanrc (see talismanrc.example) and commit again
```

## CLI mode (scan without the hook)

```bash
talisman -h             # bash: talisman: command not found  -> PATH set in .bashrc but not reloaded
source ~/.bashrc
talisman -h
talisman --scan                     # scans the git history -> talisman_reports/data/report.json
jq '.summary' talisman_reports/data/report.json
talisman --scan --ignoreHistory     # current HEAD only
talisman --scanWithHtml             # needs talisman_html_report
```

## Clean up
```bash
git reset HEAD id_rsa && rm id_rsa      # never push it
```
