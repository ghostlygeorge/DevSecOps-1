# Lab 64: Protecting Secrets in IaC with Ansible Vault

## Goal
Encrypt secrets that live alongside IaC with **ansible-vault** (AES-256),
so they can be committed and still be decrypted transparently at run time
and sent securely over SSH.

## Setup

```bash
pip3 install ansible==8.7.0                 # ansible-vault ships with it
cp ../59-ansible-adhoc/inventory.ini inventory.ini && labify inventory.ini
ssh-keyscan -t rsa $PROD_HOST $DSO_BOX >> ~/.ssh/known_hosts
ansible -i inventory.ini prod -m shell -a "uptime"
echo "hello" > example
ansible -i inventory.ini prod -m copy -a "src=example dest=/example"
ssh root@$PROD_HOST ls /                    # example is there
```

## Encrypt / use

```bash
echo "StrongP@ssw0rd" > /secret
ansible-vault encrypt /secret --ask-vault-pass        # e.g. C0mpl3xp@sswOrd. Remember it!
cat /secret
# $ANSIBLE_VAULT;1.1;AES256
# 62663235633637...
ansible -i inventory.ini prod --ask-vault-pass -m copy -a "src=/secret dest=/secret"
ssh root@$PROD_HOST "cat /secret"                     # StrongP@ssw0rd (decrypted on the fly during copy)
```

The `copy` module decrypts vaulted source files automatically. Only people
with the vault password can view or edit the file.

## The rest of the CLI

```bash
ansible-vault view /secret            # read without decrypting to disk
ansible-vault edit /secret            # opens $EDITOR, re-encrypts on save
ansible-vault decrypt /secret         # back to plaintext (careful)
ansible-vault rekey /secret           # change the password
ansible-vault create group_vars/prod/vault.yml
ansible-vault encrypt_string 'pdso-training' --name 'docker_password'    # inline encrypted var for YAML
ansible-playbook site.yml --vault-password-file ~/.vault_pass   # non-interactive
ansible-playbook site.yml --vault-id prod@prompt                 # multiple vault ids
```

## In CI
```yaml
deploy:
  script:
    - echo "$ANSIBLE_VAULT_PASSWORD" > .vault_pass && chmod 600 .vault_pass
    - ansible-playbook -i inventory.ini main.yml --vault-password-file .vault_pass
  after_script:
    - rm -f .vault_pass
```
`ANSIBLE_VAULT_PASSWORD` is a masked + protected CI variable.

## Notes
- Vault moves the problem to "protect one password". For teams, use a
  secret manager (HashiCorp Vault, AWS Secrets Manager) and look secrets
  up at run time.
- Don't log decrypted values: add `no_log: true` to tasks that handle secrets.
- Secret scanners (TruffleHog, Gitleaks) ignore `$ANSIBLE_VAULT` blobs, since
  they're high-entropy but encrypted.
