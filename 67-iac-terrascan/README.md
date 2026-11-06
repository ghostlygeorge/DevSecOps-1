# Lab 67: IaC Security with Terrascan (local, GitLab, GitHub Actions)

## Goal
Scan Terraform for compliance and security violations with **Terrascan**
(OPA/Rego policies), then embed it in GitLab (custom image entrypoint) and
GitHub Actions.

## Install

```bash
wget https://github.com/accurics/terrascan/releases/download/v1.12.0/terrascan_1.12.0_Linux_x86_64.tar.gz
tar -xvf terrascan_1.12.0_Linux_x86_64.tar.gz      # CHANGELOG.md LICENSE README.md terrascan
chmod +x terrascan && mv terrascan /usr/local/bin/
git clone https://gitlab.practical-devsecops.training/pdso/terraform.git && cd terraform
terrascan -h        # init | scan | server | version ; -o human|json|yaml|xml|junit-xml|sarif|github-sarif
```

## Scan

```bash
terrascan scan -d gcp
# Description : Ensure that Cloud SQL database instance requires all incoming connections to use SSL
# File : big_data.tf   Line : 1   Severity : HIGH
# ...
# Scan Summary - Policies Validated: 220  Violated Policies: 11  Low 0  Medium 4  High 7
terrascan scan -d aws -i terraform -o json > terrascan-aws.json
echo $?        # 3 = violations found
```

| Flag | Meaning |
|---|---|
| `-d DIR` / `-f FILE` | target |
| `-i terraform\|k8s\|helm\|docker\|cft\|arm\|kustomize` | IaC type |
| `-t aws\|gcp\|azure\|k8s\|github` | policy type |
| `--iac-version v14` | Terraform version |
| `--skip-rules ID,..` / `--scan-rules` | exclude / include |
| `--severity high` | minimum severity |

Inline skip: `#ts:skip=AC_AWS_0207 justification` in the resource.

## GitLab CI
`terraform` project ([lab 66](../66-iac-checkov) shows the push).
`ci/gitlab-ci.yml`:
- `image.entrypoint: ["/bin/sh", "-c"]`: the terrascan image's entrypoint is
  the binary itself, so GitLab couldn't run `script:` without the
  override. Every "tool image" in GitLab needs this pattern (Trivy and
  sonar-scanner use `entrypoint: [""]`).
- Binary path inside the image: `/go/bin/terrascan`.

## GitHub Actions
`ci/github-actions.yaml` uses the terrascan action with `only_warn: true`.

## Notes
- Terrascan moved `accurics/` → `tenable/` and is in maintenance mode.
  Checkov, Trivy (`trivy config`), and KICS are the actively developed
  alternatives.
- `terrascan server` runs it as an API, e.g. as a Kubernetes admission webhook.
