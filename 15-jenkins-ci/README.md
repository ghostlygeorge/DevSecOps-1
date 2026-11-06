# Lab 15: Continuous Integration with Jenkins

## Goal
Run the real django.nv build/test in Docker agents, report status back to
GitLab, then make build/test parallel and archive an artifact.

## Setup
[common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md), including
**disabling Auto DevOps** in GitLab.

```bash
source ../lab-env.sh
git config --global user.email "student@pdevsecops.com"
git config --global user.name  "student"
git clone git@${GITLAB_HOST}:root/django-nv.git && cd django-nv
git mv .gitlab-ci.yml .gitlab-ci.yml.backup      # keep it to switch back later
cp ../15-jenkins-ci/Jenkinsfile .
git add Jenkinsfile
git commit -m "Create the .gitlab-ci.yml backup and add Jenkinsfile"
git push origin main
```

> If you write the Jenkinsfile with an **unquoted** `cat > Jenkinsfile <<EOL`
> heredoc like the course does, keep the `\${env.STAGE_NAME}` backslashes.
> Otherwise bash expands `${env.STAGE_NAME}` to an empty string
> (actually a "bad substitution" error). Copying the file avoids that.

## Files
- `Jenkinsfile`: sequential build → test → integration → prod, with GitLab status updates.
- `Jenkinsfile.challenge-solution`: parallel build/test plus an `artifact` stage.

## Challenge answers

**Why `agent` in build/test?** The top-level `agent any` runs on any
executor with whatever is installed there. A per-stage `agent { docker {
image 'python:3.6' } }` gives an isolated, reproducible Python 3.6
environment. `args '-u root'` makes the container user root so
`pip install` can write. It's the Jenkins equivalent of GitLab's per-job
`image:`.

**Parallel**: wrap stages in `stage("build and test") { parallel { stage(...) stage(...) } }`.
In Blue Ocean / the stage view they then appear side by side instead of in
sequence. It's faster but consumes more executors/RAM at once, and in this
lab parallel docker agents can leave the build stuck if Jenkins has too few
executors.

**Artifact**: `archiveArtifacts artifacts: 'artifact.txt'`. Any type (JSON, CSV, HTML) works.
In security stages, archive inside `post { always { } }` so the report
survives a failing scan.

## Post conditions
| Block | Runs when |
|---|---|
| `always` | every time. Use it for cleanup and archiving reports. |
| `success` / `failure` / `unstable` / `aborted` | matching build result |

`updateGitlabCommitStatus` makes the commit/MR in GitLab show Jenkins'
result (GitLab plugin).
