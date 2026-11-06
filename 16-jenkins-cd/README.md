# Lab 16: Continuous Deployment with Jenkins

## Goal
Add a `release` stage that builds and pushes the image to the GitLab
container registry, and a `prod` stage that deploys it over SSH with the
SSH Agent plugin.

## Setup
1. Job/webhook/disable Auto DevOps: [common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md)
2. Credentials at `$JENKINS_URL/credentials/store/system/domain/_/`:

| Kind | ID | Values |
|---|---|---|
| Username with password | `registry-auth` | root / pdso-training, description "GitLab Container Registry" |
| SSH Username with private key | `ssh-prod` | Username `root`, **Enter directly** → prod's `/root/.ssh/id_rsa`, passphrase empty |

3. Plugins: **Docker Pipeline** (`docker.build`/`withRegistry`) and **SSH Agent** (`sshagent`).

## Files
- `Jenkinsfile`: replace `LABID` (`labify Jenkinsfile`) and commit it to django-nv.

## Running
Commit → `$JENKINS_URL/blue/organizations/jenkins/django.nv/activity` →
**Proceed** at the input → verify:

```bash
ssh root@$PROD_HOST docker ps
# gitlab-registry-<id>.../root/django-nv:4   0.0.0.0:8000->8000/tcp   django.nv
```

The image also shows under GitLab → Packages & Registries → Container Registry.

## Notes
- The `environment {}` block was moved from the `release` stage to the
  pipeline top so `prod` can use `$registryUrl` too. Stage-level
  `environment` is scoped to that stage only.
- `docker login -p pdso-training` is hardcoded in the course. Better:
  `withCredentials([usernamePassword(credentialsId: 'registry-auth', usernameVariable: 'U', passwordVariable: 'P')])`
  and `echo $P | docker login -u $U --password-stdin`.
- Passphrase-less deploy keys are needed for unattended automation. For
  stronger secret handling, use a secrets manager (HashiCorp Vault) rather
  than long-lived keys in Jenkins.
- Debug SSH by trying `ssh root@$PROD_HOST` from the DevSecOps-Box. If that
  works, the problem is the credential in Jenkins.
