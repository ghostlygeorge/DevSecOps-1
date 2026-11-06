# Lab 68: IaC Security with tfsec (local, GitLab, GitHub Actions)

## Goal
Static-analyse Terraform with **tfsec**, read its code-context output, and
embed it in GitLab and GitHub Actions.

## Install / scan

```bash
wget -O /usr/local/bin/tfsec https://github.com/aquasecurity/tfsec/releases/download/v0.55.0/tfsec-linux-amd64
chmod +x /usr/local/bin/tfsec
git clone https://gitlab.practical-devsecops.training/pdso/terraform.git && cd terraform
tfsec -h
tfsec aws
# Check 39 [AWS001][WARNING] Resource 'aws_s3_bucket.data' has an ACL which allows public access.
#   /terraform/aws/s3.tf:7     acl = "public-read"
#   Impact: The contents of the bucket can be accessed publicly
#   Resolution: Apply a more restrictive bucket ACL
# Check 40 [AWS017][ERROR] ... defines an unencrypted S3 bucket
# Check 41 [AWS018][ERROR] aws_security_group.default should include a description
# 41 potential problems detected.
tfsec aws -f json | tee tfsec-output.json
```

Every finding shows the code, **Impact**, **Resolution**, and a docs link,
which makes it the most developer-friendly output of the IaC scanners.

| Flag | Meaning |
|---|---|
| `-f json\|csv\|checkstyle\|junit\|sarif` | format |
| `-e ID,ID` | exclude checks |
| `-s/--soft-fail` | exit 0 even with findings |
| `--tfvars-file` | evaluate with real variable values |
| `--include-passed`, `--include-ignored` | show more |

Inline ignore: `#tfsec:ignore:AWS017` (or `:aws-s3-enable-bucket-encryption` in newer IDs).

## GitLab CI
`ci/gitlab-ci.yml`: `docker run --rm -v $(pwd):/src aquasec/tfsec /src -f json`.
The target path `/src` is passed as an argument; there's no `-w`.

## GitHub Actions
`aquasecurity/tfsec-action` with `soft_fail: true`.

## Notes
- **tfsec is deprecated**. Aqua merged it into **Trivy**:
  `trivy config aws/` gives the same checks with a maintained engine ([lab 28](../28-sca-trivy)).
- Checks were renamed from `AWS001` style to `aws-s3-no-public-access-with-acl` style
  in tfsec ≥ 0.58. The course pins 0.55.
- DefectDojo: `TFSec Scan`.
