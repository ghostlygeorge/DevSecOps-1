# Lab 60: Working with Ansible Playbooks

## Goal
Write a structured, reusable **playbook** that installs and configures
nginx, deploys django.nv behind it on the sandbox machine, and understand
idempotency (`changed=`).

## Layout

```
simple-playbook/
├── main.yml            # master playbook: hosts, user, includes tasks
├── inventory.ini       # devsecops + sandbox
├── tasks/main.yml      # the task list
└── templates/default.j2   # nginx site config (Jinja2)
```

Full convention (Ansible docs, "Sample directory layout"): `tasks/`,
`roles/<role>/{tasks,handlers,templates,vars,defaults}`, `vars/main.yml`.

## Run

```bash
pip3 install ansible==8.7.0
cp -r ../60-ansible-playbooks/simple-playbook /simple-playbook && cd /simple-playbook
labify inventory.ini
ssh-keyscan -t rsa $SANDBOX_HOST $DSO_BOX >> ~/.ssh/known_hosts
tree
ansible-playbook -i inventory.ini main.yml
# PLAY RECAP: sandbox-<id> : ok=8 changed=8 unreachable=0 failed=0
```

The course first runs this *without* `inventory.ini` in the directory and
gets `Unable to parse ... inventory.ini` → `skipping: no hosts matched`.
Ansible needs the inventory to map the `sandbox` group to real hosts.

## Verify

```bash
ssh $SANDBOX_HOST
which nginx                 # /usr/sbin/nginx
netstat -tlpn               # :80 nginx, :8000 python3 (django)
exit
curl $SANDBOX_HOST          # <title>Task Manager</title> ...
```

## Idempotency: `changed=8` → `changed=4`

Run it again. `apt`, `template`, `service`, and `git` report **ok** (the
desired state is already reached). The four `command`/`shell` tasks always
report **changed**, because Ansible can't know what a raw command did.

**Why it matters for security:** on a hardened host, a scheduled re-run
that reports `changed=0` proves nothing drifted. Any `changed>0` from
idempotent modules means someone or something altered the config.
Configuration drift detection for free. Make shell tasks idempotent with
`creates:`/`removes:` or `changed_when:`.

**Without `gather_facts`?** Fact gathering (the `setup` module) is on by
default and adds a round trip per host. This playbook uses no
`ansible_*` facts, so `gather_facts: no` is fine. Remove the line and it
still works, just slower.

## The firewalld playbook (from the hardening lab)

```bash
ansible-playbook -i /inventory.ini ../60-ansible-playbooks/playbook-firewalld.yml     # changed=1
ansible-playbook -i /inventory.ini ../60-ansible-playbooks/playbook-firewalld.yml     # changed=0
```

## Notes
- `{% raw %}...{% endraw %}` stops Jinja from touching nginx's `$host`
  variables. When the course writes the file with an unquoted bash heredoc it
  must also escape `\$host`.
- `nohup ... &` in a `shell` task is a lab shortcut. Use a systemd unit or a
  container for real services.
