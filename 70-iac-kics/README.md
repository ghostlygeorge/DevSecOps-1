# Lab 70: Securing IaC with KICS (Checkmarx)

## Goal
Scan Terraform with **KICS** ("Keeping Infrastructure as Code Secure").
Run it via Docker, produce a human-friendly **HTML** report, and serve it to
your browser.

KICS supports Terraform, Kubernetes, Docker, Ansible, CloudFormation,
Helm, OpenAPI, Pulumi, Crossplane, and more, with 2000+ queries and
secret detection.

## Why Docker instead of a binary?
KICS's binary needs its **queries** directory next to it. The image
bundles binary + queries + libraries, so there's no install to manage.

```bash
git clone https://gitlab.practical-devsecops.training/pdso/terraform && cd terraform
docker pull checkmarx/kics:v1.7.11
docker run -t -v $(pwd):/path checkmarx/kics:v1.7.11 --help
# analyze | generate-id | list-platforms | remediate | scan | version
```

| Part | Meaning |
|---|---|
| `-t` | allocate a TTY (KICS's coloured banner/progress) |
| `-v $(pwd):/path` | bind-mount CWD to `/path` in the container ([lab 08](../08-docker-volumes)) |
| `checkmarx/kics:v1.7.11` | pinned image version |

## Scan

```bash
pwd                                                   # /terraform
docker run -t -v $(pwd):/path checkmarx/kics:v1.7.11 scan
# Error: required flag(s) "path" not set
docker run -t -v $(pwd):/path checkmarx/kics:v1.7.11 scan --path "/path"
# AD Admin Not Configured For SQL Server, Severity: HIGH ... ../../path/azure/sql.tf:9
# Results Summary: HIGH: 78  MEDIUM: 60  LOW: 17  INFO: 68  TOTAL: 223
```

## HTML report

```bash
docker run -t -v $(pwd):/path checkmarx/kics:v1.7.11 scan --path "/path" --output-path "/path" --report-formats html
# Results saved to file /path/results.html   -> ./results.html on the host
```

| Flag | Meaning |
|---|---|
| `--path` | what to scan (inside the container) |
| `--output-path` | where to write reports. Use the mount so they reach the host. |
| `--report-formats` | `json` (default), `html`, `sarif`, `glsast`, `junit`, `sonarqube`, `pdf`, `csv`, `cyclonedx`, `asff`, `codeclimate`, `all` |

View it from your laptop. In a **second terminal** ([lab 05](../05-http-server-and-find)):
```bash
cd terraform && python -m http.server 80
```
then open `$DSO_BOX_URL` → `results.html`.

## Useful flags
```bash
--type Terraform                     # limit platforms
--cloud-provider aws
--exclude-severities info,low
--exclude-queries <query-id>         # FP suppression (or # kics-scan ignore-line / ignore-block in code)
--fail-on high                       # which severities affect the exit code
--ignore-on-exit results             # always exit 0 on findings (report-only)
--disable-secrets
```

Exit codes: highest severity found (60 critical, 50 high, 40 medium, 30 low, 20 info), 0 if clean.

## CI
```yaml
kics:
  stage: validate
  image:
    name: checkmarx/kics:v1.7.11
    entrypoint: [""]
  script:
    - kics scan --path . --output-path . --report-formats json,html --ignore-on-exit results
  artifacts:
    paths: [results.json, results.html]
    when: always
```
DefectDojo: `KICS Scan`.
