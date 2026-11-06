# Lab 54: DAST with Nuclei — Binary, Templates, Docker, and CI

## Goal
Run ProjectDiscovery's template-driven scanner **Nuclei** against prod
(full template set, then a targeted subset), via binary and Docker, and in
GitLab, Jenkins, and GitHub Actions.

## Install

```bash
wget https://github.com/projectdiscovery/nuclei/releases/download/v2.9.6/nuclei_2.9.6_linux_amd64.zip
unzip nuclei_2.9.6_linux_amd64.zip && mv nuclei /usr/local/bin/nuclei
nuclei --help
```

Flag groups worth knowing: **TARGET** `-u`, `-l list.txt` · **TEMPLATES**
`-t dir/file`, `-w workflow`, `-as` (automatic tech-based), `-nt` (new only),
`-validate`, `-tl` · **FILTERING** `-tags`, `-s/-severity`, `-es`,
`-id`, `-eid`, `-etags` · **OUTPUT** `-o`, `-j/-jsonl`, `-je` JSON,
`-se` SARIF, `-me` markdown, `-silent` · **RATE** `-rl`, `-c`, `-bs`,
`-timeout`, `-retries` · **DEBUG** `-v`, `-debug`, `-stats`.

## Scan

```bash
nuclei -u $PROD_URL           # first run downloads nuclei-templates to ~/nuclei-templates (~6000 templates)
# [nginx-version] [http] [info] ... [nginx/1.18.0]
# [email-extractor] [http] [info] ... [info@tm.com]
# [http-missing-security-headers:content-security-policy] [http] [info] ...
# [django-debug] [http] [medium] .../NON_EXISTING_PATH/          <- real finding: DEBUG=True
# [django-admin-panel] [http] [info] .../admin/login/?next=/admin/
# [openssh-detect] [tcp] [info] ...:22 [SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5]

nuclei -u $PROD_URL -j -o nuclei-output.json      # JSON Lines
cat nuclei-output.json | jq
jq -r '"\(.info.severity)\t\(.["template-id"])\t\(.["matched-at"])"' nuclei-output.json | sort | uniq -c
```

Each finding includes `template-id`, `template-path`, `info.severity`,
`matched-at`, `extracted-results`, and a `curl-command` to reproduce it,
which is great for false-positive analysis.

## Targeted template scans

```bash
git clone https://github.com/projectdiscovery/nuclei-templates.git && cd nuclei-templates
nuclei -u $PROD_URL -t http/misconfiguration/       # 434 templates instead of ~6000
```

**How do you find which template produced a finding?** Look at
`template-id` / `template-path` in the JSON output, then run just that
template with `-t <path>` or `-id <template-id>`.

Ignore `[WRN] ... deprecated protocol syntax`: old templates use
`requests:` where newer ones use `http:`.

## Docker

```bash
docker pull projectdiscovery/nuclei:v2.9.6
cd / && rm nuclei-output.json && ls
docker run --user $(id -u):$(id -g) -w /nuclei -v $(pwd):/nuclei:rw --rm projectdiscovery/nuclei:v2.9.6 \
  -u $PROD_URL -j -o nuclei-output.json
cat nuclei-output.json | jq
```

The binary and the container give the same results. Docker avoids
installing anything, which is ideal for CI. Note that the container
re-downloads templates on every run unless you mount a templates cache
(`-v ~/nuclei-templates:/root/nuclei-templates` or `-ud`).

## CI

| System | File | Stage |
|---|---|---|
| GitLab | `ci/gitlab-ci.yml` | `integration` |
| Jenkins | `ci/Jenkinsfile` | `integration` with `catchError` (`\$(id -u)` escaped for Groovy) |
| GitHub (docker) | `ci/github-actions-docker.yaml` | secret `PROD_URL` |
| GitHub (action) | `ci/github-actions-marketplace.yaml` | `projectdiscovery/nuclei-action` writes `nuclei.log` |

## Notes
- **Nuclei exits 0 even when it finds things.** To gate, check the output:
  `test $(jq -s '[.[] | select(.info.severity=="high" or .info.severity=="critical")] | length' nuclei-output.json) -eq 0`
- Running all ~6000 templates takes minutes and sends thousands of
  requests. In CI use `-tags`, `-severity`, specific dirs, or **workflows**
  ([lab 58](../58-nuclei-workflows)).
- DefectDojo: `Nuclei Scan` (JSONL).
