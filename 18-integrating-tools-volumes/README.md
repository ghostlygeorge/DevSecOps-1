# Lab 18: How to Integrate Any Tool Into a CI/CD Pipeline

## Goal
A repeatable method for onboarding a new security tool: research it, run
it locally in Docker, get the **volume mounts** and **output redirection**
right, and only then move it to CI.

## The method
1. **Research**: official docs and `--help`. Look specifically for: input
   path flag, output format/file flags, exit-code behaviour, and the
   expected working directory.
2. **Find the image**: Docker Hub / GHCR. Note the name **and a pinned
   version**.
3. **Run locally** in the DevSecOps-Box until it produces a report file in
   your CWD.
4. **Then** paste the same command into the pipeline, adding
   `allow_failure` + `artifacts`.

## Scenario 1: ZAP (tool writes its own report file)

```bash
docker pull ghcr.io/zaproxy/zaproxy:stable
docker run --rm ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -h

docker run --user $(id -u):$(id -g) -v $(pwd):/zap/wrk/:rw -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t $PROD_URL -r testreport.html
```
- ZAP writes reports relative to **`/zap/wrk`**. That's the documented
  contract, so the volume **must** mount there, `:rw`.
- `--user $(id -u):$(id -g)` makes the container write files you own (no
  root-owned `testreport.html` you can't delete).

## Scenario 2: Safety (tool prints to stdout)

Where you put `>` decides where the file ends up:

```bash
# Redirect INSIDE the container (inside sh -c): file is written in the container's CWD.
# Only lands on the host if that CWD is inside the mount -> here -w is NOT set, so it's lost.
docker run --rm -v $(pwd):/project hysnsec/safety sh -c "safety check -r /project/requirements.txt --json > output.json"

# Redirect OUTSIDE the container: the HOST shell captures stdout -> file on the host.
docker run --rm -v $(pwd):/src hysnsec/safety check -r requirements.txt --json > output.json
```

| Pattern | File location |
|---|---|
| `sh -c "tool > out.json"` | inside the container. Survives only if written under a mounted path (e.g. `> /project/out.json`) |
| `docker run ... tool > out.json` | host CWD |
| `docker run ... tool -o /src/out.json` | host, via the `/src` mount |
| `docker run ... tool \| tee out.json` | host, plus visible in the job log |

## Checklist for docker-run scanners
- [ ] `--rm`
- [ ] `-v $(pwd):<path the tool expects>` (`/src`, `/zap/wrk`, `/path`, `/share`, `/nuclei`)
- [ ] `-w <that path>` if the tool uses relative paths
- [ ] output written **into the mount** or redirected on the host
- [ ] `--user $(id -u):$(id -g)` when files must be cleaned up afterwards
- [ ] machine-readable format (JSON/XML/SARIF) for DefectDojo
- [ ] pinned image tag
- [ ] exit-code behaviour understood ([lab 06](../06-exit-codes))

## Image → mount path reference (from the labs)
| Image | Mount | Example |
|---|---|---|
| `hysnsec/safety`, `hysnsec/bandit`, `hysnsec/trufflehog`, `hysnsec/auditjs`, `hysnsec/bundle-audit` | `/src` | `-v $(pwd):/src` |
| `zaproxy/zap-stable` / `softwaresecurityproject/zap-stable` | `/zap/wrk` | `-v $(pwd):/zap/wrk:rw -w /zap` |
| `checkmarx/kics` | `/path` | `-v $(pwd):/path` |
| `zricethezav/gitleaks` | `/path` | `-v $(pwd):/path -w /path` |
| `hysnsec/inspec` | `/share` (hard requirement) | `-v $(pwd):/share` |
| `projectdiscovery/nuclei` | anything + `-w` | `-v $(pwd):/nuclei:rw -w /nuclei` |
| `semgrep/semgrep` | `/src` | `-v $(pwd):/src` |
| `bridgecrew/checkov`, `securego/gosec` | `/src` + `-w /src` | |
| `public.ecr.aws/portswigger/dastardly` | `/dastardly` | env `BURP_REPORT_FILE_PATH=/dastardly/x.xml` |
| `hysnsec/nikto`, `hysnsec/sslyze`, `hysnsec/nmap` | `/tmp` | `-o /tmp/out.xml` |
