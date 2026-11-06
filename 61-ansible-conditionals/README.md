# Lab 61: Ansible Conditionals — `when`, Facts, and `register`

## Goal
Run tasks only when conditions hold, using gathered **facts** or the
**registered** result of an earlier task. Hardening roles use this pattern
to behave correctly across distros.

## Setup

```bash
pip3 install ansible==8.7.0
cp ../59-ansible-adhoc/inventory.ini /inventory.ini && labify /inventory.ini   # devsecops + sandbox are used
ssh-keyscan -t rsa $SANDBOX_HOST $DSO_BOX >> ~/.ssh/known_hosts
mkdir /myplaybook && cd /myplaybook
cp -r /inventory.ini inventory.ini     # without this: "skipping: no hosts matched"
```

## `when` with facts

```bash
cp /path/to/61-ansible-conditionals/when.yml main.yml
ansible-playbook -i inventory.ini main.yml        # ok: "This system uses Ubuntu-based distro" x2
ansible -i inventory.ini all -m setup             # discover every fact (ansible_distribution, ansible_os_family, ...)
ansible -i inventory.ini all -m setup -a "filter=ansible_distribution*"
```

Change the condition to `"CentOS"` and both hosts show **skipping**.
`gather_facts: yes` is required. Without it `ansible_distribution` is undefined.

## `register`

```bash
cp /path/to/61-ansible-conditionals/register.yml main.yml
ansible-playbook -i inventory.ini main.yml
```

A registered variable has `.rc`, `.stdout`, `.stdout_lines`, `.stderr`,
`.changed`, `.failed` (`stat` gives `.stat.exists`, ...).
`.find('Ubuntu') != -1` is Python's `str.find`, which returns -1 when the
substring is absent. A cleaner Jinja form: `when: "'Ubuntu' in os_release.stdout"`.

## Challenges (combined answer: `challenge-main.yml`)

```bash
mkdir /challenges && cp /inventory.ini /challenges/
cp /path/to/61-ansible-conditionals/challenge-main.yml /challenges/main.yml
ansible-playbook -i /challenges/inventory.ini /challenges/main.yml
```

1. `stat` `/usr/sbin/nginx`, register `stat_nginx`
2. if it exists: `nginx -v` → print `nginx_version.stderr` (nginx prints its version to **stderr**)
3. if missing: install with `apt`. First run installs (and skips the version
   tasks). Second run prints the version and skips the install.

The course's first two answers target `hosts: all`. The final answer narrows
to `hosts: sandbox`.
