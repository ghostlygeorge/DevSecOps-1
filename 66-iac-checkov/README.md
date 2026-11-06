# Lab 66: IaC Security with Checkov (local, GitLab, Jenkins)

## Goal
Find security misconfigurations in Terraform with **Checkov**
(Bridgecrew/Prisma), skip accepted checks, and embed it in a new
`validate` stage in GitLab and Jenkins.

Checkov supports Terraform, CloudFormation, Kubernetes, Helm, Dockerfile,
ARM/Bicep, Serverless, GitHub/GitLab CI configs, and secrets.

## Install / scan

```bash
pip3 install checkov==2.3.22
git clone https://gitlab.practical-devsecops.training/pdso/terraform.git
checkov -h
checkov -f terraform/aws/s3.tf
# terraform scan results:  Passed checks: 29, Failed checks: 22, Skipped checks: 0
# Check: CKV_AWS_93 ... PASSED for resource: aws_s3_bucket.data   File: /s3.tf:1-13   Guide: https://docs.bridgecrew.io/docs/bc_aws_s3_24
checkov -d terraform/aws
```

Each check has an ID (`CKV_AWS_18` access logging, `CKV_AWS_19` SSE,
`CKV_AWS_20` public-read ACL, `CKV_AWS_21` versioning, `CKV_AWS_52` MFA delete ...)
and a guide link with the fix.

## Challenges

```bash
# 1. whole repo -> JSON
checkov -d /terraform/ -o json > /terraform/scan-result.json
# 2. number of failed checks
jq ".[0].summary.failed" /terraform/scan-result.json
#    (-d on a repo with several frameworks -> output is an ARRAY, one element per framework,
#     so [0] is the first framework only; to sum them: jq '[.[].summary.failed] | add')
# 3. skip specific checks
checkov -d /terraform/ -o json --skip-check CKV_AWS_18,CKV_AWS_21,CKV_AWS_20,CKV_AWS_52,CKV_AWS_19 > /terraform/scan-result-skipped.json
```

Other suppression methods:
- Inline: `#checkov:skip=CKV_AWS_20:Public website bucket by design` inside the resource block.
- `--baseline` / `--create-baseline`: accept current findings, report only new ones.
- `.checkov.yaml` config file (`--create-config` / `--config-file`).
- `--soft-fail`, `--soft-fail-on`, `--hard-fail-on HIGH`: exit-code policy.

## GitLab CI

```bash
git clone https://gitlab.practical-devsecops.training/pdso/terraform.git terraform && cd terraform
git remote rename origin old-origin
git remote add origin git@${GITLAB_HOST}:root/terraform.git
git push -u origin --all          # (or create the blank project in the UI first)
```
Then `ci/gitlab-ci.yml`: a new **validate** stage **first**, since IaC
should be checked before anything is built.

> **Course erratum:** the first course version uses `stage: validate`
> without adding `validate` to `stages:`, and GitLab rejects it with
> `chosen stage does not exist`. The final version adds it, as here.

Note `| tee checkov-output.json`: with tee the job never fails ([lab 06](../06-exit-codes)).
For a real gate, use `-o json --output-file-path .` (writes `results_json.json`).

## Jenkins
Job `terraform`, webhook `/project/terraform`
([common/JENKINS-JOB-SETUP.md](../common/JENKINS-JOB-SETUP.md)). The course
pushes over HTTP with `git checkout -b main && git push -u origin main`.
`ci/Jenkinsfile`.

## Notes
- DefectDojo: `Checkov Scan`.
- `bridgecrew/checkov` is unpinned. Pin a version tag in CI.
