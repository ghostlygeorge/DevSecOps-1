# Lab 63: Deploying a Docker Container with Ansible

## Goal
Build and push the django.nv image to the lab registry, then deploy it to
prod with an Ansible playbook using the `docker_*` modules. This is the
Ansible alternative to the SSH-heredoc deploy in [lab 13](../13-gitlab-continuous-deployment).

## Setup

```bash
pip3 install ansible==8.7.0
mkdir ~/playbook && cp ../63-ansible-docker-deploy/{inventory.ini,main.yml} ~/playbook/
labify ~/playbook/inventory.ini ~/playbook/main.yml
ssh-keyscan -t rsa $PROD_HOST $DSO_BOX >> ~/.ssh/known_hosts
ansible -i ~/playbook/inventory.ini prod -m shell -a "docker version"
```

**Why `ansible_python_interpreter=/usr/bin/python3` on prod?** It forces
the interpreter Ansible uses on that host. Auto-discovery can pick a
different Python than the one where `pip3 install docker` puts the SDK,
and then you get `No module named 'docker'` even though it's installed.

## Build and push

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv.git ~/django.nv && cd ~/django.nv
docker build -t $REGISTRY_HOST/django.nv:1.0 .       # build + tag with the registry in one step
docker push $REGISTRY_HOST/django.nv:1.0             # "no basic auth credentials"
echo "pdso-training" | docker login --username root --password-stdin $REGISTRY_HOST
docker push $REGISTRY_HOST/django.nv:1.0
cd ~/
```

## Deploy

```bash
cd ~/playbook
ansible-playbook -i inventory.ini -e "docker_username=root docker_password=pdso-training" main.yml
ansible -i inventory.ini prod -m shell -a "docker ps"     # django.nv  0.0.0.0:8000->8000/tcp
```

Without the `pip` task you get: *Failed to import the required Python
library (Docker SDK for Python ...) on prod's Python /usr/bin/python3*. The
lab prod may already have it, so you might not see the error. If "Remove
django.nv container" errors once, rerun.

## Notes
- `-e "docker_password=..."` puts the password in shell history and `ps`.
  Use **Ansible Vault** ([lab 64](../64-ansible-vault)):
  `ansible-vault encrypt_string 'pdso-training' --name docker_password >> group_vars/prod.yml`.
- Modules are now FQCN `community.docker.docker_login` etc.
- **In CI** this becomes: release job pushes `:$CI_COMMIT_SHA` → deploy job
  runs `ansible-playbook -e image_tag=$CI_COMMIT_SHA`. Have a go at writing it.
