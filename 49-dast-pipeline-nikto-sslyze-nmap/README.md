# Lab 49: Build → Deploy → DAST with Nikto, SSLyze and Nmap in GitLab

## Goal
DAST needs a **running** app. Build the image, deploy it to prod from the
pipeline, then run three DAST tools against it in parallel, non-blocking,
with artifacts.

## Steps

1. Start from the simple build/test pipeline (stages `build`, `deploy`, `test`).
2. Replace `build` with a docker build/push. The first try fails with
   `denied: access forbidden`, because you have to `docker login` with the
   predefined `$CI_REGISTRY_USER` / `$CI_REGISTRY_PASSWORD` first. Where do
   `CI_REGISTRY_IMAGE` and `CI_COMMIT_SHA` come from? They're
   [predefined GitLab variables](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html),
   so no secrets are needed. Check **Packages & Registries → Container Registry**.
3. Add CD variables `PROD_USERNAME`, `PROD_HOSTNAME`, `PROD_SSH_PRIVKEY` ([lab 13](../13-gitlab-continuous-deployment)).
4. Add the `prod` deploy job (`needs: [build]` so it starts as soon as the build is done).
5. Challenge: add `nikto`, `sslscan`, `nmap` jobs using `hysnsec/*` images.

Final file: `gitlab-ci.yml` (`labcat` it to replace `LABID`).

Task Manager after deploy: `$PROD_URL` (admin/admin).

## Why `-v $(pwd):/tmp` and `/tmp/<file>`
These hysnsec images run with `/tmp` as their working/output dir. Mounting
the job directory there makes the reports appear in the job workspace,
where `artifacts:` can pick them up.

## When to run DAST?
No fixed rule. Run it after deployment to dev/staging/prod, wherever your
organisation needs it. Scan the **staging** environment in the pipeline,
and scan production on a schedule. Missing tools? Install them if you're
allowed, or ask ops.

## Don't block builds (ML 1–2)
If a security job fails it blocks deploys and frustrates DevOps, and DAST
tools have false positives. **Don't block builds unless you're sure about
the result's quality.** All three jobs have `allow_failure: true`.

## Extra mile (no official solution)
Write your own SSLyze image on alpine and use it in the pipeline:
`Dockerfile.sslyze` is a starting point.

## Notes
- **Course erratum**: `${CI_REGISTRY_PASS}` → `$CI_REGISTRY_PASSWORD` (fixed here).
- Stage order `build → deploy → test` makes the test (DAST) stage run
  against the **just-deployed** commit.
