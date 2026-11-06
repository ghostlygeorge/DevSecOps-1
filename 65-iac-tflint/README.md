# Lab 65: Linting Terraform with TFLint (+ GitHub Actions)

## Goal
Catch Terraform errors and bad practice **before** `terraform apply`:
illegal instance types, deprecated syntax, unused declarations, naming
conventions. Then run TFLint in GitHub Actions.

## Install

```bash
curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
tflint --version          # 0.49.x + ruleset.terraform (bundled)
git clone https://gitlab.practical-devsecops.training/pdso/terraform.git && cd terraform
tflint -h
```

Key options: `--chdir=DIR`, `--recursive`, `-f default|json|checkstyle|junit|compact|sarif`,
`--init` (install plugins), `--enable-rule/--disable-rule/--only`,
`--var-file`, `--minimum-failure-severity`, `--force`, `--fix`.

TFLint scans **one directory** at a time. Use `--recursive` (or the
`--chdir` loop) for multiple modules.

## Run

```bash
tflint --chdir=aws
# Failed to load configurations; aws/consts.tf:29,13-21: Invalid quoted type constraints;
# Terraform 0.11 and earlier required type constraints to be given in quotes ... Remove the quotes around "string".
# (6 occurrences: lines 29, 34, 40, 45, 51, 57)
```

This repo (TerraGoat-style) is written in **Terraform 0.11 syntax**:
`type = "string"`. Since 0.12, types are bare keywords. TFLint can't even
parse it. Fix:

```bash
sed -i 's/type *= *"\(string\|number\|bool\|list\|map\)"/type = \1/' aws/consts.tf
tflint --chdir=aws
```

Fixing these errors now prevents runtime failures at `terraform plan/apply`.

## Cloud-provider rules
The bundled ruleset only covers Terraform-language issues. For AWS
specifics (e.g. `t1.2xlarge` doesn't exist) add the AWS plugin
(`tflint.hcl.example` → `.tflint.hcl`, then `tflint --init`).

## GitHub Actions
Repo `terraform` ([common/GITHUB-REPO-SETUP.md](../common/GITHUB-REPO-SETUP.md)),
workflow `ci/github-actions.yaml`: `terraform-linters/setup-tflint` +
`tflint --chdir=aws -f json > tflint-output.json`, `continue-on-error`,
artifact with `if: always()`.

## Exit codes
`0` clean, `1` error (like this parse failure), `2` issues found, `3`
both. `--force` gives 0.

TFLint is a **linter** (correctness and conventions). Checkov, tfsec,
Terrascan, and KICS are **security** scanners. Use both kinds.
