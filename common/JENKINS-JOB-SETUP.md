# Jenkins job + GitLab webhook setup (shared by every Jenkins lab)

Every "How To Embed X Into Jenkins" exercise begins with these identical
steps. Do them once per Jenkins machine (Jenkins resets after 2 hours).

Credentials for both GitLab and Jenkins: `root` / `pdso-training`.

## 1. Create the pipeline job

1. Open `$JENKINS_URL/newJob`.
2. Item name: `django.nv` (or `golang`, `terraform`, ... — match the repo).
3. Choose **Pipeline** → **OK**.

## 2. Generate a webhook token

1. **Build Triggers** tab → tick **Build when a change is pushed to GitLab**.
2. Click **Advanced** (below *Comment (regex) for triggering a build*).
3. Under **Secret token** click **Generate**. Copy the token.

## 3. Add the webhook in GitLab

1. Log into `$GITLAB_URL` first (a 404 means you're not logged in).
2. Open `$GITLAB_URL/root/django-nv/hooks` (Settings → Webhooks).
3. URL: `$JENKINS_URL/project/django.nv`
4. Secret token: paste the token from step 2 → **Add webhook**.

> **Why `/project/django.nv` and not `/job/django.nv`?** `/job/<name>` is the
> Jenkins UI page for the job. `/project/<name>` is the endpoint registered
> by the **GitLab plugin** that receives GitLab webhook payloads and
> validates the secret token. Posting to `/job/...` gets a 403 or a login
> page, not a build.

## 4. Point the job at the repo

1. **Pipeline** tab → Definition: **Pipeline script from SCM**.
2. SCM: **Git**. Repository URL: `http://gitlab-ce-LABID.lab.practical-devsecops.training/root/django-nv.git`
3. You get `HTTP Basic: Access denied` — click **Add → Jenkins** and create:
   | Field | Value |
   |---|---|
   | Username | root |
   | Password | pdso-training |
   | ID | `gitlab-auth` |
4. Select the new credential in the dropdown. The error disappears.
5. **Branch Specifier**: change `*/master` → `*/main`.
6. **Save**.

## 5. Stop GitLab from also running the pipeline

- Delete or rename `.gitlab-ci.yml` (`git mv .gitlab-ci.yml .gitlab-ci.yml.backup`).
- **Disable Auto DevOps**: `$GITLAB_URL/root/django-nv/-/settings/ci_cd` →
  untick *Default to Auto DevOps pipeline*. Otherwise GitLab runs an Auto
  DevOps pipeline even with no `.gitlab-ci.yml`.

## 6. Add the Jenkinsfile

GitLab UI → **+** → **New file** → name `Jenkinsfile` → paste → **Commit
changes**. The push fires the webhook and the build starts at
`$JENKINS_URL/job/django.nv`.

## Jenkins credential types you'll create later

| Lab | Kind | ID | Value |
|---|---|---|---|
| CD / Ansible / InSpec | SSH Username with private key | `ssh-prod` | user `root`, key = prod's `/root/.ssh/id_rsa`, empty passphrase |
| Ansible / InSpec | Secret text | `prod-server` | `prod-LABID` |
| Registry push | Username and password | `registry-auth` | root / pdso-training |
| DefectDojo | Secret text | `dojo-host` | `dojo-LABID.lab.practical-devsecops.training` |
| DefectDojo | Secret text | `dojo-api-token` | token from `$DOJO_URL/api/key-v2` |

Store: `$JENKINS_URL/credentials/store/system/domain/_/` → **Add Credentials**.

## Troubleshooting

- **Stuck build**: Jenkins agents are heavier than GitLab runners; abort
  older running builds so only one runs at a time.
- **`No such DSL method 'updateGitlabCommitStatus'`**: GitLab plugin missing.
- **`docker.build` / `docker.withRegistry` not found**: Docker Pipeline plugin missing.
- **`sshagent` not found**: SSH Agent plugin missing.
