# Lab 83: Automated Upload to DefectDojo from Jenkins

## Goal
Same loop as [lab 82](../82-defectdojo-gitlab-automation), in Jenkins: a
`sast` stage runs Bandit and uploads, and (challenge) a `zap-baseline` stage
plus a `defectdojo` stage upload ZAP results.

## Setup
1. [common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md) (job `django.nv`, Auto DevOps off).
2. Credentials (Secret text) at `$JENKINS_URL/credentials/store/system/domain/_/`:
   - `dojo-host` = `dojo-<id>.lab.practical-devsecops.training`
   - `dojo-api-token` = token (from `$DOJO_URL/api/key-v2`, or
     `curl -s -XPOST -H 'content-type: application/json' $DOJO_URL/api/v2/api-token-auth/ -d '{"username":"root","password":"pdso-training"}' | jq -r .token`)
3. Commit `upload-results.py` (from `common/`) and `Jenkinsfile` (`labify` it first).

The first build fails with `python3: can't open file 'upload-results.py'`
until the script is committed.

## Key points
- `withCredentials([string(...)])` injects secrets as env vars, masked in the log.
- `bandit ... || true`: inside a multi-line `sh` the first failing command
  aborts the block (`sh -e`), so without `|| true` the upload never runs.
  The course's comment says the same.
- Single-quoted `sh '''...'''` lets the shell, not Groovy, expand
  `$DOJO_API_TOKEN`. Groovy interpolation of secrets leaks them into the
  build's command record, and Jenkins warns about it.
- **Challenge:** `zap-baseline` → `defectdojo` stages. Both run on the same
  agent/workspace, so the XML is just there. Across agents use
  `stash`/`unstash` or the *Copy Artifact* plugin
  (`copyArtifacts projectName: env.JOB_NAME, selector: specific(env.BUILD_NUMBER), filter: 'zap-output.xml'`).
- Jenkins needs `python3` + `requests` on the agent for the uploader. If
  missing, run that stage in `agent { docker { image 'python:3.11-slim' } }`
  with `pip install requests`.

**500 from Dojo**: environment name or scanner/format mismatch (see lab 81).
