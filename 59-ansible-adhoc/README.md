# Lab 59: Ansible Basics — Inventory, Config, Ad-hoc Commands

## Goal
Manage the lab fleet with Ansible: write an inventory, configure
`ansible.cfg`, and run **ad-hoc** commands (ping, shell, apt, copy) across
machines. It's the foundation for automated hardening.

Ansible is agentless: it pushes Python modules over **SSH** and describes
desired state in readable YAML.

## Install

```bash
pip3 install ansible==8.7.0          # ansible 8.x bundles ansible-core 2.15
ansible --version                    # config file = None
```

## Inventory

```bash
cp ../59-ansible-adhoc/inventory.ini /inventory.ini && labify /inventory.ini
cd /
ansible -i inventory.ini prod --list-hosts       # hosts (1): prod-<id>
ansible -i inventory.ini gitlab --list-hosts     # WARNING: Could not match supplied host pattern -> hosts (0)
```

`[group]` headings group hosts. INI and YAML formats are both supported.
`all` is the implicit group of everything.

## ansible.cfg

```bash
mkdir -p /etc/ansible && cp /path/to/59-ansible-adhoc/ansible.cfg /etc/ansible/ansible.cfg
ansible --version                    # config file = /etc/ansible/ansible.cfg
```

Precedence: `$ANSIBLE_CONFIG` > `./ansible.cfg` (playbook dir) >
`~/.ansible.cfg` > `/etc/ansible/ansible.cfg`. On CentOS
`/etc/ansible/ansible.cfg` exists by default.

## Ad-hoc commands

Ad-hoc = one task, fast, not reusable (playbooks are reusable).

```bash
ssh-keyscan -t rsa $DSO_BOX $SANDBOX_HOST $PROD_HOST >> ~/.ssh/known_hosts   # no yes/no prompts
ansible -i inventory.ini all -m ping                 # "ping": "pong" x3 (an Ansible-level ping, not ICMP)
ansible -i inventory.ini all -m shell -a "hostname"
ansible -i inventory.ini all -m apt -a "name=ntp"
ansible -i inventory.ini prod -m shell -a "uptime"   # uptime of 500 servers in one command
ansible -i inventory.ini all -m command -a "bash --version"
```

`python3-apt must be installed and visible from /usr/bin/python3` means an
interpreter mismatch. Fix it with:
```bash
export ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3.8
```

`command` vs `shell`: `command` has no shell, so pipes, redirects, and `$VAR`
don't work, and that makes it safer (no injection). Use `shell` only when you
need shell features.

## Module docs

```bash
ansible-doc -l | egrep "add_host|amazon.aws.aws"
ansible-doc -l | grep shell
ansible-doc copy                    # full docs + EXAMPLES section
```

## Challenges

```bash
ansible-doc -h                                                    # 1 help -> module for sending files = copy
echo "test" > /root/notes                                          # 2
ansible -i inventory.ini all -m copy -a "src=/root/notes dest=/root"   # 3 copy to every machine
ansible-doc -l | grep shell                                        # find the shell module
ansible -i inventory.ini prod -m shell -a "uptime"                  # uptime on prod
```

## `CHANGED` vs `SUCCESS`
`changed: true` means the module modified the host. `ping`/`uptime` via
`shell` always report CHANGED because Ansible can't tell whether a shell
command changed anything. Idempotent modules (`apt`, `copy`) report OK on a
second run. This matters for security too (next lab).
