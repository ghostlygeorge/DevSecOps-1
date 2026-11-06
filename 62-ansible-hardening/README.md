# Lab 62: OS Hardening with Ansible Roles (local, GitLab CI, Jenkins)

## Goal
Harden the production Ubuntu server with the community **dev-sec
os-hardening** role from Ansible Galaxy. Run it locally, then as a
pipeline job (GitLab and Jenkins) so hardening is continuous, not a one-off.

## Setup

```bash
pip3 install ansible==8.7.0 ansible-lint==6.8.1
cp ../62-ansible-hardening/inventory.ini . && labify inventory.ini
ssh-keyscan -t rsa $PROD_HOST $GITLAB_HOST $DSO_BOX >> ~/.ssh/known_hosts
ansible -i inventory.ini prod -m apt -a "name=ntp state=present"
ansible -i inventory.ini all -m command -a "bash --version"
```

## Ansible Galaxy

```bash
ansible-galaxy role --help        # init | remove | list | search | info | install ...
ansible-galaxy search terraform   # q to quit the pager
ansible-galaxy install secfigo.terraform     # -> /root/.ansible/roles/secfigo.terraform
```

### Challenge: install Terraform via a role
```bash
mkdir /challenge && cd /challenge && cp ../inventory.ini .
cp /path/to/62-ansible-hardening/terraform-playbook.yml playbook.yml
ansible-galaxy install secfigo.terraform
ansible-playbook -i /challenge/inventory.ini /challenge/playbook.yml
# ok=2 changed=0 skipped=1 -> "Download and Install Terraform" skipped because it's already installed
```

## Harden prod

```bash
mkdir /hardening && cd /hardening && cp ../inventory.ini .
cp /path/to/62-ansible-hardening/ansible-hardening.yml .
ansible-galaxy install dev-sec.os-hardening
ansible-playbook -i inventory.ini ansible-hardening.yml
# PLAY RECAP: prod-<id> : ok=42 changed=20 ... skipped=28
ansible-playbook -i inventory.ini ansible-hardening.yml      # rerun: changed drops towards 0 (idempotent)
```

What it does (selection): auditd installed and configured, removes group
write on system binary paths, sysctl network/kernel hardening (no IP
forwarding, ASLR, no core dumps), password/login policy (`login.defs`,
PAM), disables unused filesystems, restricts cron/at, removes SUID bits on
known-unneeded binaries, and more.

Hardening changes can break apps (e.g. disabling IPv4 forwarding breaks
Docker networking). The role exposes variables for that, such as
`sysctl_overwrite: {net.ipv4.ip_forward: 1}`. Test on staging first.

## In GitLab CI
1. Variables: `DEPLOYMENT_SERVER` = `prod-<id>`, `DEPLOYMENT_SERVER_SSH_PRIVKEY` = prod's key.
2. Append the `ansible-hardening` job (`ci/gitlab-ci.yml`).
3. The first run fails with `ERROR! the playbook: ansible-hardening.yml could not be found`.
   The playbook isn't in the repo yet. Add it via `$GITLAB_URL/root/django-nv/-/new/main/`
   (name it `ansible-hardening.yml`) or with git.
4. `Permission denied` or `Enter passphrase for /root/.ssh/id_rsa` means the key variable is wrong or truncated.

`echo "$KEY" | tr -d '\r' > ~/.ssh/id_rsa` writes the key (stripping
Windows CRs), and `eval "$(ssh-agent -s)"` + `ssh-add` gives SSH the key
non-interactively.

## In Jenkins
Credentials `ssh-prod` (SSH key) and `prod-server` (secret text). Stage in
`ci/Jenkinsfile` after `prod` uses `sshagent` + `withCredentials` so no host
or key is hardcoded. Commit `ansible-hardening.yml` too.

## ansible-lint
```bash
ansible-lint ansible-hardening.yml     # best-practice/security lint of playbooks (no plaintext secrets, FQCN, etc.)
```

## Notes
- `dev-sec.os-hardening` (legacy role name) now lives in the **`devsec.hardening`
  collection**: `ansible-galaxy collection install devsec.hardening`, role
  `devsec.hardening.os_hardening`. The lab images still use the old name.
- Pin role versions (`requirements.yml`). An unpinned hardening role that
  changes upstream changes your production servers.
- Pair with InSpec `linux-baseline` ([lab 71](../71-inspec-basics)): Ansible
  **enforces**, InSpec **verifies**. Same dev-sec project, matching rules.
