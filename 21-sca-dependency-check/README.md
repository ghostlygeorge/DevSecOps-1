# Lab 21: SCA with OWASP Dependency-Check

## Goal
Scan a Java project (WebGoat) with OWASP Dependency-Check, fail on a CVSS
threshold, suppress a false positive, and run it in GitLab CI and GitHub
Actions.

## Setup

```bash
git clone https://github.com/WebGoat/WebGoat.git webapp
java -h || { apt update && apt install openjdk-8-jre -y; }      # newer DC versions need Java 11+
wget -O /opt/v8.3.1.zip https://github.com/jeremylong/DependencyCheck/releases/download/v8.3.1/dependency-check-8.3.1-release.zip
unzip /opt/v8.3.1.zip -d /opt/
export PATH=/opt/dependency-check/bin:$PATH
dependency-check.sh -h
```

## 1. Scan

```bash
dependency-check.sh --scan /webapp --format "JSON" --project "Webgoat" --out /opt
# first run downloads the whole NVD feed: minutes
ls /opt/dependency-check-report.json
```

## 2. `--failOnCVSS` (fail the build)

```bash
dependency-check.sh --scan /webapp --format "JSON" --project "Webgoat" --failOnCVSS 4 --out /opt
echo $?          # 15: bootstrap/jquery/underscore >= 4.0 listed
dependency-check.sh --scan /webapp --format "JSON" --project "Webgoat" --out /opt
echo $?          # 0: default threshold is 11, so it never fails
```

## 3. Suppress a false positive (CVE-2021-23358)

```bash
cp ../21-sca-dependency-check/suppression.xml .
dependency-check.sh --scan /webapp --format "JSON" --project "Webgoat" --failOnCVSS 7 --suppression suppression.xml --out /opt
# no underscore-min.js line. Without --suppression:
dependency-check.sh --scan /webapp --format "JSON" --project "Webgoat" --failOnCVSS 7 --out /opt
# One or more dependencies ... >= '7.0': underscore-min.js: CVE-2021-23358(7.2)
```

> **Course erratum:** the course command reads `--suppression suppression.xml--out /opt`
> (no space), which makes DC look for a file literally named
> `suppression.xml--out`. Keep the space.

Suppression files are the DC equivalent of Bandit's baseline or Retire's
`.retireignore.json`. Selectors: `vulnerabilityName`, `cve`, `cpe`,
`packageUrl`, `filePath` (regex), `cvssBelow`. Add `until=` so they expire.
The HTML report has a **suppress** button that generates the XML for you.

## 4. Which stage?
Early: build, or any stage **before** packaging into a JAR or image. Catch
vulnerable dependencies before they're baked into an artifact.

## 5. GitLab CI (webgoat project)

```bash
git clone https://github.com/WebGoat/WebGoat.git webgoat && cd webgoat
git remote rename origin old-origin
git remote add origin http://gitlab-ce-${LAB_ID}.lab.practical-devsecops.training/root/webgoat.git
git push -u origin --all          # creates the project (root / pdso-training)
cp ../21-sca-dependency-check/ci/run-depcheck.sh .
cp ../21-sca-dependency-check/ci/gitlab-ci.yml .gitlab-ci.yml
git add run-depcheck.sh .gitlab-ci.yml && git commit -m "add dependency-check" && git push
```

`run-depcheck.sh` mounts three volumes: source → `/src`, a persistent NVD
**data** dir (avoids re-downloading the database), and a **reports** dir.
The job fails because of `--failOnCVSS 4`, and `allow_failure: true` lets the pipeline continue.

## 6. GitHub Actions
`ci/github-actions.yaml` uses the marketplace action
`dependency-check/Dependency-Check_Action`. Reports end up in
`${{ github.workspace }}/reports`. See [common/GITHUB-REPO-SETUP.md](../common/GITHUB-REPO-SETUP.md)
(repo name `webgoat`).

## Notes
- **NVD API key**: since 2023 the NVD rate-limits feed downloads heavily.
  DC 9+ needs `--nvdApiKey` (free from NVD) or first runs take hours. Pin
  8.3.1 for the course.
- Pin the action to a tag/SHA rather than `@main` in real pipelines
  (supply-chain risk, see Renovate in lab 26).
- DefectDojo scanner name: `Dependency Check Scan` (XML format).
