# Lab 53: DAST with Dastardly (Burp Suite's free CI scanner)

## Goal
Run PortSwigger's **Dastardly**, a lightweight Burp-engine scanner
designed for CI. Compare it with ZAP.

```bash
docker pull public.ecr.aws/portswigger/dastardly
docker run --user $(id -u) --rm -v $(pwd):/dastardly \
  -e BURP_START_URL=https://casp-pm-${LAB_ID}.lab.practical-devsecops.training/apispec_1.json \
  -e BURP_REPORT_FILE_PATH=/dastardly/dastardly-output.xml \
  public.ecr.aws/portswigger/dastardly
# ... Crawl finished / Audit started / Audit finished
# Issue identified. Path: /robots.txt, Issue Type: Vulnerable JavaScript dependency, Severity: LOW
# ERROR dastardly.ScanFinishedHandler - Failing build as scanner identified issue(s) with severity higher than "INFO"
ls -l dastardly-output.xml
```

| Env var | Meaning |
|---|---|
| `BURP_START_URL` | where to start crawling |
| `BURP_REPORT_FILE_PATH` | **JUnit XML** report path inside the container (so put it under the mount) |

Read the JUnit XML in a JUnit viewer (the course suggests an online one),
or in GitLab:

```yaml
dastardly:
  stage: integration
  script:
    - docker run --user $(id -u) --rm -v $(pwd):/dastardly -e BURP_START_URL=$PROD_URL -e BURP_REPORT_FILE_PATH=/dastardly/dastardly-report.xml public.ecr.aws/portswigger/dastardly:latest
  artifacts:
    reports:
      junit: dastardly-report.xml    # findings show up in the pipeline's Tests tab
    when: always
  allow_failure: true
```

## ZAP vs Dastardly
| | ZAP baseline | Dastardly |
|---|---|---|
| Scan type | passive | light **active** checks (Burp engine) |
| Duration limit | configurable | max ~10 min, fixed config |
| Output | JSON/XML/HTML/MD | JUnit XML |
| Exit | 0/1/2/3 | fails on anything above INFO |
| Tuning | config/progress files, contexts, auth | almost none |
| Cost | free/OSS | free (Burp Enterprise for more) |

Pick based on what you need to tune, the time budget, and which report
formats your vulnerability management tooling accepts.

Docs: <https://portswigger.net/burp/dastardly>. By running it you accept PortSwigger's EULA.
