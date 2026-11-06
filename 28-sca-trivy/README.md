# Lab 28: SCA with Trivy (filesystem, image, and more)

## Goal
Use **Trivy**, Aqua's all-in-one scanner, to find vulnerable dependencies
in a source tree. Know its other modes too, since one binary covers SCA,
container images, IaC misconfig, secrets, and SBOMs.

## Install

```bash
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.1/trivy_0.48.1_Linux-64bit.deb && dpkg -i trivy_*.deb
trivy -h
```

| Command | Scans |
|---|---|
| `trivy fs .` / `trivy filesystem .` | local directory: lockfiles + secrets (+ misconfig with `--scanners`) |
| `trivy image python:3.4-alpine` | container image: OS packages + app deps |
| `trivy image --input ruby-3.1.tar` | saved image tarball |
| `trivy repo <url>` | remote git repo |
| `trivy config .` | IaC misconfig (Terraform/K8s/Dockerfile). The successor to tfsec. |
| `trivy sbom sbom.json` | vulnerabilities in an SBOM |
| `trivy k8s`, `trivy aws`, `trivy vm` | experimental |

## Scan

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv.git webapp && cd webapp
trivy filesystem .
# Need to update DB -> Downloading DB (ghcr.io/aquasecurity/trivy-db) ...
# requirements.txt (pip)  Total: 14 (MEDIUM: 5, HIGH: 6, CRITICAL: 3)
#   Django CVE-2021-31542 HIGH 3.0 -> fixed 2.2.21, 3.1.9, 3.2.1  Potential directory-traversal via uploaded files
```

## Flags you'll use

```bash
trivy fs --scanners vuln .                         # skip secret scanning (faster)
trivy fs --severity HIGH,CRITICAL .                # filter the REPORT (unlike retire's --severity)
trivy fs --exit-code 1 --severity CRITICAL .       # the CI gate (default exit is 0!)
trivy fs --ignore-unfixed .                        # hide vulns with no fix available
trivy fs -f json -o trivy.json .                   # machine readable (DefectDojo: "Trivy Scan")
trivy fs -f cyclonedx -o sbom.cdx.json .           # SBOM
echo "CVE-2021-31542" >> .trivyignore              # FP / accepted-risk mechanism
```

## CI
`gitlab-ci-trivy.yml` (bonus) shows `trivy fs` in `test` and `trivy image`
against the freshly built registry image in `release`. Note
`entrypoint: [""]`: the trivy image's entrypoint is `trivy`, which would
swallow GitLab's shell script.

## Notes
- Scanning the **image** finds things scanning the repo can't: OS packages
  in the base image (e.g. `python:3-alpine3.15` musl/openssl CVEs).
  Do both.
- The DB is cached in `~/.cache/trivy`. Cache that dir in CI to avoid
  re-downloading ~40 MB per job.
