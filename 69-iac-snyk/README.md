# Lab 69: IaC Security with Snyk (`snyk iac test`)

## Goal
Use the same Snyk CLI from [lab 22](../22-sca-snyk) to find misconfigurations
in Terraform.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/terraform && cd terraform
wget -O /usr/local/bin/snyk https://github.com/snyk/cli/releases/download/v1.1105.0/snyk-linux
chmod +x /usr/local/bin/snyk
snyk iac --help
```

Options: `--severity-threshold=low|medium|high`, `--json`, `--json-file-output=FILE`
(write JSON **and** keep human output), `--sarif`, `--sarif-file-output`,
`--detection-depth=N`, `--experimental` (local engine, Terraform plan JSON).

Exit codes: `0` clean, `1` issues, `2` failure, `3` no supported files.

## Scan

```bash
snyk iac test aws --json
# FailedToGetIacOrgSettingsError: Failed to fetch IaC organization settings   <- not authenticated
snyk auth YOUR_API_TOKEN_HERE          # free personal account: https://app.snyk.io/account
# or: export SNYK_TOKEN=YOUR_TOKEN_HERE
snyk iac test aws --json > snyk-output.json
jq '[.[]?.infrastructureAsCodeIssues[]? // .infrastructureAsCodeIssues[]?] | group_by(.severity) | map({(.[0].severity): length}) | add' snyk-output.json
```

`aws` is the target directory. Point it at any path with Terraform/K8s/CloudFormation.

## Also scannable
```bash
snyk iac test deployment.yaml                    # Kubernetes
terraform plan -out tf.plan && terraform show -json tf.plan > tf-plan.json
snyk iac test tf-plan.json                       # evaluates resolved values (modules, variables)
```

Scanning the **plan** catches issues hidden behind variables/modules that
static HCL scanning can't resolve.

## In CI
Same pattern as lab 22: `SNYK_TOKEN` as a protected/masked CI variable,
`snyk iac test --json-file-output=snyk-iac.json`, artifact, `allow_failure`.
