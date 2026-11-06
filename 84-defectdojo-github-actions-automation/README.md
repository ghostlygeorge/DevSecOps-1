# Lab 84: Automated Upload to DefectDojo from GitHub Actions

## Goal
Bandit runs in GitHub Actions and the results go straight to the lab
DefectDojo.

## Setup
1. [common/GITHUB-REPO-SETUP.md](../common/GITHUB-REPO-SETUP.md): repo
   `django.nv`, push protection disabled, PAT.
2. Repo **Settings → Secrets → Actions**:
   - `DOJO_HOST` = `dojo-<id>.lab.practical-devsecops.training`
   - `DOJO_API_TOKEN` = token from `$DOJO_URL/api/key-v2`
3. Commit `upload-results.py` (`common/`) and `.github/workflows/main.yaml` = `github-actions.yaml`.

```bash
cp ../common/upload-results.py .
git add upload-results.py .github/workflows/main.yaml
git commit -m "bandit + defectdojo upload" && git push origin main
```

## Key points
- `if: always()` on the artifact, setup-python, and upload steps, so the
  upload runs even if Bandit fails. (`continue-on-error` on the scan does
  that too. `always()` is belt and braces.)
- The course uses `setup-python@v2` with 3.6. Use current versions; the uploader needs `requests`.
- **The lab DefectDojo must be reachable from GitHub's hosted runners**
  (public internet). If your Dojo is internal-only, use a self-hosted
  runner inside the network.
- 500 errors: environment name / scanner format (lab 81).
