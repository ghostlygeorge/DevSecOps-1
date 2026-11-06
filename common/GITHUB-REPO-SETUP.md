# GitHub repo + PAT setup (shared by every GitHub Actions lab)

> Use a personal throwaway GitHub account — never your employer's account
> or tokens. These repos intentionally contain hardcoded secrets.

## 1. Repo
Create `https://github.com/new` → name `django.nv` (or `webgoat`,
`terraform`). Don't initialise it.

If the repo is **public**, GitHub push protection will reject the push
because django.nv contains fake AWS keys. Disable it:
`https://github.com/<user>/<repo>/settings/security_analysis` → disable
**Push protection** / **Secret scanning**.

## 2. Personal Access Token
Passwords don't work for git over HTTPS (since Aug 2021).

- Classic: `https://github.com/settings/tokens` → *Generate new token (classic)* →
  scopes **repo** + **workflow** → token looks like `ghp_...`
- Fine-grained: `https://github.com/settings/personal-access-tokens/new` →
  All repositories → Repository permissions *Read & Write* for **Actions**,
  **Contents**, **Workflows** → token looks like `github_pat_...`

The **workflow** scope matters: without it pushing anything under
`.github/workflows/` is rejected.

Save it on the DevSecOps-Box: `echo ghp_xxx > ~/gh-token && chmod 600 ~/gh-token`.

## 3. Push the course repo to GitHub

```bash
git config --global user.email "your_email@example.com"
git config --global user.name  "your_username"

git clone https://gitlab.practical-devsecops.training/pdso/django.nv.git
cd django.nv
git remote rename origin old-origin
git remote add origin https://github.com/<user>/django.nv.git
git push -u origin main            # username = GitHub user, password = PAT
# already pushed before?          git push -u origin main --force
# typo'd the remote?               git remote remove origin
```

## 4. Workflow file
Any `*.yaml`/`*.yml` under `.github/workflows/` is a workflow:

```bash
mkdir -p .github/workflows
cp <lab>/ci/github-actions.yaml .github/workflows/main.yaml
git add .github/workflows/main.yaml
git commit -m "Add github workflows"
git push origin main
```

Results: repo → **Actions** tab → pick the run.

## 5. Secrets
Repo → **Settings → Secrets and variables → Actions → New repository
secret**. Reference as `${{ secrets.NAME }}`.

## GitLab ↔ GitHub Actions ↔ Jenkins cheat-table

| Concept | GitLab CI | GitHub Actions | Jenkins |
|---|---|---|---|
| Pipeline file | `.gitlab-ci.yml` | `.github/workflows/*.yaml` | `Jenkinsfile` |
| Unit of work | job | job | stage |
| Ordering | `stages:` list | `needs:` (otherwise **parallel**) | sequential by default; `parallel {}` |
| Container | `image:` | `container:` / `docker run` / `runs-on` | `agent { docker { image } }` |
| Commands | `script:` | `steps: - run:` | `steps { sh "" }` |
| Don't fail build | `allow_failure: true` | `continue-on-error: true` | `catchError(buildResult:'SUCCESS', stageResult:'UNSTABLE')` |
| Keep report | `artifacts: paths: when: always` | `actions/upload-artifact` + `if: always()` | `archiveArtifacts` in `post { always {} }` |
| Branch filter | `only: [main]` / `rules:` | `on: push: branches:` | multibranch / `when { branch 'main' }` |
| Secrets | Settings → CI/CD → Variables | Settings → Secrets | Credentials store + `withCredentials` |
| Manual gate | `when: manual` | environments + required reviewers | `input "Deploy?"` |
