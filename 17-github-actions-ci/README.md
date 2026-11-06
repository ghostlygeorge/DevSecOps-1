# Lab 17: Continuous Integration with GitHub Actions

## Goal
Run the same build/test/integration/prod flow on GitHub Actions and learn
its biggest difference from GitLab: **jobs run in parallel unless you
chain them with `needs:`**.

## Setup
[common/GITHUB-REPO-SETUP.md](../common/GITHUB-REPO-SETUP.md): repo
`django.nv`, PAT with `repo`+`workflow`, push the course code.

## Files
| File | Purpose |
|---|---|
| `demo.yaml` | course demo: echo jobs, no `needs` |
| `demo-solution.yaml` | challenge answers: `needs`, `continue-on-error`, artifact upload |
| `main.yaml` | the real Django build/test workflow used by every later GHA lab |

```bash
mkdir -p .github/workflows
cp ../17-github-actions-ci/demo.yaml .github/workflows/demo.yaml
git add .github/workflows/demo.yaml && git commit -m "Add github workflows" && git push origin main
```
Results: repo → **Actions**.

## Challenge answers
1. **Why didn't `prod` fail when `integration` did?** Jobs without `needs`
   are independent and run in parallel on separate runners. A failed job
   only affects jobs that `need` it, and nothing needed `integration`. (The
   workflow run as a whole is still marked failed.)
2. **Sequential + tolerate failure**: add `needs: <previous>` to each job,
   and `continue-on-error: true` on the failing **step**.
   `continue-on-error` can go on a step (that step's failure is ignored) or
   on a job (the job's failure doesn't fail the workflow).
3. **Artifact**: `actions/upload-artifact@v4` with `name`/`path`. Download it
   from the run summary page.

## Version note
The course YAML uses `ubuntu-20.04`, `actions/checkout@v2`,
`upload-artifact@v2`, and Python 3.6. All of those were **removed** by
GitHub in 2025 (the ubuntu-20.04 runner retired April 2025, and
upload-artifact v1–v3 returns an error). Every workflow in this repo uses
`ubuntu-22.04`, `checkout@v4`, `upload-artifact@v4`, `setup-python@v5` with
Python 3.8 (Django 3.0 supports 3.8).

## `if: always()`
Steps are skipped once an earlier step fails. `if: always()` on the
upload step means the **report is uploaded even when the scanner failed**,
and that's exactly when you want it. It's the same idea as GitLab's
`artifacts: when: always`.
