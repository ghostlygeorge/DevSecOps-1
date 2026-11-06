# Lab 12: GitLab CI — Stages and Conditional Pipelines (`rules`)

## Goal
Understand the stage model every exam pipeline uses, and control **when**
a job runs with `rules:`, which replaces `only`/`except`.

## Stages
| Stage | Purpose |
|---|---|
| build | produce a runnable build. Proves the code compiles/packages. |
| test | unit → integration → end-to-end tests. Security SCA/SAST jobs usually go here or in build. |
| integration | merge with other services, deploy to staging, UAT. DAST usually goes here. |
| deploy/prod | ship to users with blue/green, canary, or rolling deploys |

Jobs in the same stage run **in parallel**. Stages run **in order**. A
failed job stops later stages unless it has `allow_failure: true`.

## Files (`examples/`)
| File | Shows |
|---|---|
| `01-stages.yml` | four stages, `allow_failure`, `when: manual` |
| `02-rules-if-branch.yml` | `$CI_COMMIT_BRANCH == "main"` |
| `03-rules-if-mr.yml` | `$CI_PIPELINE_SOURCE == "merge_request_event"` |
| `04-rules-changes.yml` | run only when a file changed, combined with `if` |
| `05-rules-exists.yml` | run only when a file exists |
| `06-rules-allow-failure-and-manual.yml` | per-rule `allow_failure`, tag-only manual job |
| `07-workflow-and-only.yml` | `workflow:rules`, `allow_failure:exit_codes`, legacy `only` |

## Running
Paste each file into `$GITLAB_URL/root/django-nv/-/blob/main/.gitlab-ci.yml`
→ **Edit** → **Commit changes**, then watch `$GITLAB_URL/root/django-nv/-/pipelines`.

For `06`: the `job5` tag job doesn't appear on a branch push. Go to
**Repository → Tags → New tag** (`for-practice`) and the tag pipeline shows
`job5` with a ▶ play button.

## Rule semantics to memorise
- Rules are evaluated **top-down, first match wins**. No match means the job is **not added**.
- A matching rule without `when:` means `when: on_success`, `allow_failure: false`.
- `when: never` excludes the job. Put it first to blacklist cases.
- Inside one rule, `if` + `changes` + `exists` are **ANDed**.
- You can't use `rules:` and `only/except` in the same job.

## Notes: ways to run a tool, any of which can go in CI
| Method | Pros | Cons |
|---|---|---|
| Native install (`pip install bandit`) | simple | slow every job, dependency clashes |
| Package/binary (`wget .../tfsec && chmod +x`) | fast, no deps | must manage versions |
| **Docker image** (`docker run hysnsec/bandit`) | no deps, reproducible, **recommended for CI** | needs dind / docker socket |

The course repeats this note after almost every tool. All three are valid,
so choose based on the situation.

## Gotcha
A job that sets `image: python:3.6` can't run `docker ...` (no docker CLI).
Docker-based scanners need the default `image: docker:20.10` +
`services: [docker:dind]` from `common/gitlab-ci-base.yml`.
