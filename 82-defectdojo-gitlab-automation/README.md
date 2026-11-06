# Lab 82: Automated Upload of Scan Results to DefectDojo from GitLab CI

## Goal
Every pipeline run uploads its SAST (Bandit) and DAST (ZAP) results to
DefectDojo automatically, closing the loop from scan to vulnerability
management.

Machines: GitLab, DefectDojo (`root`/`pdso-training`), and prod (Task
Manager `admin`/`admin`, the ZAP target).

## 1. CI/CD variables
`$GITLAB_URL/root/django-nv/-/settings/ci_cd` → Variables:

| Key | Value |
|---|---|
| `DOJO_HOST` | `dojo-<id>.lab.practical-devsecops.training` |
| `DOJO_API_TOKEN` | from `$DOJO_URL/api/key-v2` (Masked) |

## 2. Commit the uploader
The first pipeline fails if `upload-results.py` isn't in the repo.

```bash
git config --global user.email "student@pdevsecops.com"
git config --global user.name "student"
git clone git@${GITLAB_HOST}:root/django-nv.git && cd django-nv
cp ../common/upload-results.py .     # or curl the course snippet
git add upload-results.py && git commit -m "Add upload-results.py file" && git push origin main
```

## 3. Pipeline
`gitlab-ci.yml` = base + `sast` (Bandit) + `dast-zap` jobs.

Key design points:
- **`after_script`** runs the upload **even when the scanner failed** (exit 1).
  In `script:` the upload would be skipped after the failing scan.
- `apk add py-pip py-requests`: the default `docker:20.10` image is Alpine,
  which has no Python requests.
- ZAP report **XML** (`-x`), because DefectDojo's ZAP parser expects XML.
- Engagement/product IDs are hardcoded to 1. Use CI variables for real projects.

Now every developer push scans and uploads. Check the engagement in Dojo:
there's a new test per run (with dedupe flagging repeats).

## Challenge (tasks)
1. Locally: `docker run ... zap-baseline.py -t $PROD_URL -d -x zap-output.xml` into `/django-nv/zap-output.xml`
2. Locally: upload with `upload-results.py ... --scanner "ZAP Scan"`
3. In CI: the `dast-zap` job with the upload in `after_script` (as in `gitlab-ci.yml`)

## Notes
- **500** errors: check the Environment name (Engagements → Environments) and the parser format.
- `after_script` runs in a separate shell. Variables exported in `script:`
  aren't visible there, but files are.
- In production pipelines, prefer the `reimport-scan` endpoint with
  `test_title` so each tool updates one test and closes fixed findings.
