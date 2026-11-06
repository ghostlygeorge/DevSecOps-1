# Lab 79: Running InSpec in a Jenkins Pipeline

## Goal
Run the linux-baseline compliance scan against prod from Jenkins, using
the SSH Agent plugin for the key, `catchError` for exit 100, and an archived
JSON report.

## Setup
1. Job/webhook/Auto DevOps off: [common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md)
2. Credentials (`$JENKINS_URL/credentials/store/system/domain/_/`):
   - `ssh-prod`: SSH Username with private key, user `root`, **Enter directly** prod's
     `/root/.ssh/id_rsa`, no passphrase (unattended automation; use Vault for stronger handling)
   - `prod-server`: Secret text `prod-<id>` (keeps the hostname out of the Jenkinsfile)
3. Commit `Jenkinsfile` from this lab.

## How the stage works
- `agent { docker { image 'hysnsec/inspec'; args '-u root' } }`: InSpec
  comes from an image, so nothing is installed on Jenkins.
- `sshagent(['ssh-prod'])` loads the key into an agent for the stage.
  InSpec's SSH transport uses it automatically, so no `-i` is needed.
- `--reporter json:inspec-output.json` writes the report into the
  workspace, and `archiveArtifacts` in `post { always }` keeps it.
- `catchError(buildResult:'SUCCESS', stageResult:'UNSTABLE')` makes exit
  100 (control failures) show the stage as unstable and the build as passed.

> **Course erratum:** the course runs `-t ssh://root@prod-server`, the
> credential **ID**, as a hostname. That only resolves if a host is
> literally named `prod-server`. This Jenkinsfile binds the secret with
> `withCredentials` and uses `$PROD`. Single quotes on `sh '...'` let the
> **shell** expand `$PROD`, which avoids Groovy interpolating a secret
> (Jenkins warns about that).

## Notes
- Host key: the hysnsec/inspec image has no known_hosts. If the SSH
  transport complains, add `ssh-keyscan -t rsa $PROD >> ~/.ssh/known_hosts`
  before `inspec exec`.
- Same scan in GitLab: [lab 71](../71-inspec-basics).
