# Lab 71: Compliance as Code with InSpec — Run a Baseline, Embed in CI

## Goal
Audit the production server against the **dev-sec linux-baseline**
profile with Chef InSpec, then run it continuously from GitLab CI. Every
deviation from policy becomes immediate feedback to DevOps.

InSpec compares the **actual** state of a system with the **desired**
state written as readable Ruby DSL, and reports violations. It doesn't
remediate. You stay in control of fixes (that's Ansible's job, [lab 62](../62-ansible-hardening)).

## Install

```bash
bash ../71-inspec-basics/install-inspec.sh     # .deb 5.22.29, plus StrictHostKeyChecking accept-new in ~/.ssh/config
inspec --help
```

| Command | Purpose |
|---|---|
| `inspec exec LOCATION` | run a profile (path, git URL, Supermarket, Automate) |
| `inspec init profile NAME` | scaffold a profile |
| `inspec check PATH` | validate profile syntax/metadata |
| `inspec shell` | interactive REPL ([lab 73](../73-inspec-shell)) |
| `inspec vendor` | fetch dependencies → `inspec.lock` ([lab 75](../75-inspec-dependencies)) |
| `inspec detect` | identify the target OS |
| `inspec archive` / `json` / `export` | package / describe profiles |

## Run against prod

```bash
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config     # stop the ssh yes/no prompt
inspec exec https://github.com/dev-sec/linux-baseline.git -t ssh://root@$PROD_HOST -i ~/.ssh/id_rsa --chef-license accept
# ✔ os-01: Trusted hosts login
# ✔ os-02: Check owner and permissions for /etc/shadow ...
# ↺ sysctl-31b ... Skipped control due to only_if condition.
# Profile Summary: 17 successful controls, 3 control failures, 38 controls skipped
# Test Summary: 65 successful, 8 failures, 38 skipped
echo $?      # 100
```

| Flag | Meaning |
|---|---|
| 1st arg | the profile (here straight from GitHub) |
| `-t ssh://user@host` | target. Also `docker://ctr`, `winrm://`, `local://`, `aws://` |
| `-i KEY` | SSH private key |
| `--chef-license accept` | accept the EULA non-interactively |
| `--reporter cli json:out.json` | multiple reporters at once |

Exit codes: `0` pass, `100` ≥1 failure, `101` only skips.

**Skipped ≠ passed.** Most sysctl controls are skipped because the
target is a container, where `only_if { !container? }` applies.

## Embed in GitLab CI
1. Variables at `$GITLAB_URL/root/django-nv/-/settings/ci_cd`: `DEPLOYMENT_SERVER`
   = `prod-<id>`, `DEPLOYMENT_SERVER_SSH_PRIVKEY` = prod's `/root/.ssh/id_rsa`.
2. Append the `inspec` job (`ci/gitlab-ci.yml`).
3. The job fails with **exit code 100** (control failures). Fix the controls
   or add `allow_failure: true`.

`/share` is mandatory with `hysnsec/inspec`. It's a custom image whose
working directory is `/share`, and other paths won't capture the report.

> **Course erratum:** the job runs on `docker:20.10` (Alpine) with no
> `ssh-agent`/`ssh-keyscan`. `ci/gitlab-ci.yml` adds
> `apk add openssh-client`. Reporter docs: <https://docs.chef.io/inspec/reporters>.

## Notes
- Remote scanning requires nothing on the target. InSpec runs commands over SSH.
- The same profile works against containers: `-t docker://<id>` ([lab 78](../78-inspec-docker)).
