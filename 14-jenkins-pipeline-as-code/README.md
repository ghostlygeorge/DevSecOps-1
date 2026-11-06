# Lab 14: Pipeline as Code with Jenkins

## Goal
Wire Jenkins to GitLab (connection, webhook, credentials) and run a
declarative `Jenkinsfile` stored in the repo.

## One-time: configure Jenkins ↔ GitLab connection
(The lab Jenkins usually has this pre-configured.)

1. GitLab → `/-/profile/personal_access_tokens` → name `Jenkins`, scope
   **api** → **Create** → save the token (it's shown once).
2. Jenkins → `/configure` → **GitLab** section:
   - Connection name: `gitlab-server` (the lab's preconfigured one is named
     `gitlab`, which is why every Jenkinsfile says `gitLabConnection('gitlab')`)
   - GitLab host URL: `$GITLAB_URL`
   - Credentials → **Add → Jenkins** → Kind **GitLab API token** → paste
     token, ID `gitlab-api-token`
   - **Test Connection** → `Success` → **Save**

## Job + webhook
Follow [common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md) (job
`django.nv`, webhook to `/project/django.nv`, credential `gitlab-auth`,
branch `*/main`).

## Pipeline
1. Delete `.gitlab-ci.yml` in GitLab (otherwise both systems run).
2. **+ → New file** `Jenkinsfile` → paste `Jenkinsfile` from this lab → commit.
3. Watch `$JENKINS_URL/job/django.nv`. `integration` turns orange/unstable,
   and `prod` waits for you to click **Proceed**.

## Declarative vs scripted
| | Declarative (`pipeline { }`) | Scripted (`node { }`) |
|---|---|---|
| Syntax | fixed structure, validated | free Groovy |
| Learning curve | low | high |
| Used in this course | yes | no |

Differences from GitLab:
- Stages are declared inline. There's no top-level `stages:` list.
- Jenkins lets you define Groovy **functions** and call them from stages,
  instead of long `&&` chains.
- `sh "..."` runs shell. Triple-quoted `sh """ ... """` gives a multi-line script.
