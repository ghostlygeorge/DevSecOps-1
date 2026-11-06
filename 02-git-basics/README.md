# Lab 02: Git — Local Work, Branches, Merge Requests

## Goal
Clone, commit, and push to the lab GitLab. Work on branches and merge
through a Merge Request. Everything in DevSecOps (pipelines, IaC,
compliance profiles) lives in Git.

## Setup

```bash
source ../lab-env.sh
git config --global user.email "student@pdevsecops.com"
git config --global user.name  "student"
```

Wait ~2 minutes for GitLab after starting the exercise.

## 1. Clone, change, stage, commit, push

```bash
git clone git@${GITLAB_HOST}:root/django-nv.git     # answer "yes" to the host-key prompt
cd django-nv
ls -l

cat > myfile <<EOL
This is my file
EOL
echo "Practical DevSecOps" >> README.md

git status                 # README.md modified, myfile untracked
git add myfile README.md
git status                 # both under "Changes to be committed"
git commit -m "Add myfile and update README.md"
git push
```

Two steps to get a change into the repo: **stage** (`git add`) and then
**commit**. A third step, `git push`, publishes it to the server. Git works
offline, so commits stay local until you push.

View: `$GITLAB_URL/root/django-nv` (root / pdso-training).

## 2. Branches

```bash
git branch new-branch              # create only
git branch --list                  # * main / new-branch
git branch --show-current
git checkout new-branch            # switch to an existing branch
git checkout -b checkout-branch    # create + switch
git switch -c switch-branch        # create + switch (newer syntax)
git switch new-branch              # switch to an existing branch
```

| Command | Creates? | Switches? |
|---|---|---|
| `git branch X` | yes | no |
| `git checkout -b X` / `git switch -c X` | yes | yes |
| `git checkout X` / `git switch X` | no | yes |

`git switch` exists because `checkout` was overloaded (it also restores
files). Prefer `switch` for branches and `restore` for files.

## 3. Push a branch and open an MR

```bash
git switch new-branch
echo "I am ready to be awesome with Practical DevSecOps" >> README.md
git add README.md
git commit -m "update the new text to README.md"
git push origin new-branch
```

The push output prints a link
`$GITLAB_URL/root/django-nv/-/merge_requests/new?merge_request%5Bsource_branch%5D=new-branch`.
Open it (log in first if it 404s), then: **Assign to me**, set Reviewer to
Administrator, **Create merge request**, and **Merge**.

## 4. Pull the merged result and clean up

```bash
git switch main
git pull origin main               # fast-forwards with the merged change
git branch -D new-branch checkout-branch switch-branch
git branch --list                  # * main
```

Be on `main` before deleting the others. You can't delete the branch you're
on, and `main` is protected, so don't delete it.

- **remote branch**: lives in GitLab (`origin/main`)
- **local branch**: lives in your clone and tracks a remote branch

## Notes
- You can edit `.gitlab-ci.yml` either in the GitLab Web IDE or via
  clone/edit/commit/push. Both trigger the pipeline the same way. The CLI is
  faster once you're editing pipelines repeatedly.
- `git push -u origin --all` pushes every local branch and creates the
  project if it doesn't exist (GitLab "push to create"). Later labs use it
  to import webgoat, golang, rails, nodejs, and terraform.
- Further viewing: "Automation Step by Step" Git basics on YouTube.
