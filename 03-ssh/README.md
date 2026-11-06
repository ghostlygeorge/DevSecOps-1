# Lab 03: SSH — Remote Login, Remote Commands, Key Setup

## Goal
SSH is how CD jobs deploy, how Ansible manages hosts, and how InSpec
audits them. Learn the client-side commands and the key setup
behind password-less automation.

## 1. Login and remote commands

```bash
source ../lab-env.sh
ssh -i ~/.ssh/id_rsa root@$PROD_HOST    # -i chooses the private key
hostname                                  # prod-<id>
exit

ssh root@$PROD_HOST "hostname"           # runs remotely, prints prod-<id>
ssh root@$PROD_HOST "docker ps"
```

## 2. Killing the host-key prompt (essential for CI)

`Are you sure you want to continue connecting (yes/no)?` hangs a pipeline
forever. Three ways to avoid it, from safest to least safe:

```bash
# a) pin the key up front: what every CD job in this course does
ssh-keyscan -t rsa $PROD_HOST >> ~/.ssh/known_hosts
ssh-keyscan -t rsa $PROD_HOST $GITLAB_HOST $DSO_BOX >> ~/.ssh/known_hosts   # several at once

# b) trust-on-first-use, then enforce it: used by the InSpec labs
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config

# c) disable checking (only seen in the Jenkins CD stage). Vulnerable to MITM.
ssh -o StrictHostKeyChecking=no root@$PROD_HOST
```

`ssh-keyscan` in CI still trusts whatever answers on first contact. For
real production, store the known host fingerprint as a CI variable and
write it to `known_hosts` instead of scanning.

## 3. Key setup (review only — don't run in the lab)

Running these can lock you out of lab machines. Read them, don't execute them.

```bash
# server side (/etc/ssh/sshd_config), then: service sshd restart
PubkeyAuthentication yes
# (RSAAuthentication is SSHv1-only and ignored by modern OpenSSH)

# client side
ssh-keygen -t rsa                     # -> ~/.ssh/id_rsa (private), ~/.ssh/id_rsa.pub (public)
ssh-copy-id -i ~/.ssh/id_rsa.pub user@targetserver   # appends to ~/.ssh/authorized_keys on the server
```

| Item | Purpose |
|---|---|
| `sshd` | Server daemon, must allow pubkey auth |
| `ssh-keygen` | Creates the key pair. Prefer `-t ed25519` today. |
| private key | Never shared. In CI it's a **masked/protected variable**. |
| public key | Goes in `~/.ssh/authorized_keys` on the target |
| `ssh-copy-id` | Appends your pubkey to the target's `authorized_keys` |

## 4. The CI pattern you'll reuse

```yaml
before_script:
  - mkdir -p ~/.ssh
  - echo "$PROD_SSH_PRIVKEY" | tr -d '\r' > ~/.ssh/id_rsa   # tr strips Windows CRs from pasted keys
  - chmod 600 ~/.ssh/id_rsa                                  # ssh refuses keys readable by others
  - eval "$(ssh-agent -s)"                                   # start agent, export SSH_AUTH_SOCK
  - ssh-add ~/.ssh/id_rsa
  - ssh-keyscan -t rsa $PROD_HOSTNAME >> ~/.ssh/known_hosts
```

Copy the **whole** key including `-----BEGIN RSA PRIVATE KEY-----` and
`-----END RSA PRIVATE KEY-----`, otherwise you get `error in libcrypto` or
`Enter passphrase`.

```bash
ssh root@$PROD_HOST "cat /root/.ssh/id_rsa"   # what goes into PROD_SSH_PRIVKEY
```
