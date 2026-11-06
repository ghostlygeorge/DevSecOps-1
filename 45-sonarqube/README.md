# Lab 45: Code Quality and Security with SonarQube — Scans, Quality Gates, Custom Rules

## Goal
Scan django.nv with **sonar-scanner**, view Bugs/Vulnerabilities/Code
Smells/Hotspots in the SonarQube dashboard, enforce a **Quality Gate**,
write a **custom rule**, and run the scan from GitHub Actions or GitLab CI.

SonarQube login: `$SONAR_URL` → `admin` / `pdso-training`. Wait ~2 min after start.

## 1. Install the scanner

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
bash ../45-sonarqube/install-sonar-scanner.sh
export PATH=/opt/sonar-scanner-4.7.0.2747-linux/bin/:$PATH
```

## 2. Create the project and token
SonarQube → **Manually** → display name `Django`, key `Django` (unique per
project) → **Set Up** → **Locally** → token name `Django` → **Generate**
(`sqp_...`, shown **once**) → Continue → Other → Linux.

```bash
export SONARQUBE_TOKEN=sqp_xxxxxxxx
sonar-scanner \
  -Dsonar.projectKey=Django \
  -Dsonar.sources=. \
  -Dsonar.host.url=$SONAR_URL \
  -Dsonar.login=$SONARQUBE_TOKEN
```

First run: `ERROR: Error when running: 'node -v'. Is Node.js available
during analysis?` The JS/CSS analysers need Node. Install it
(`bash ../20-sca-retirejs/install-node.sh`) and rerun until
`ANALYSIS SUCCESSFUL ... EXECUTION SUCCESS`. Then open
`$SONAR_URL/dashboard?id=Django`.

Instead of `-D` flags you can commit `sonar-project.properties` (provided).

## 3. Quality Gates

Default gate **Sonar way** (on **new code**):

| Metric | Fails when |
|---|---|
| Coverage | < 80% |
| Duplicated lines | > 3% |
| Maintainability rating | worse than A (tech-debt ratio ≥ 5%) |
| Reliability rating | worse than A (any bug) |
| Security Hotspots reviewed | < 100% |
| Security rating | worse than A (any vulnerability) |

Custom gate for the stakeholder requirement "**no vulnerabilities at all**":

1. **Quality Gates → Create** → `Django Gate` → Save
2. Select it → **Set as Default** → **Unlock editing** → **Add Condition**
3. **On Overall Code** → *Vulnerabilities* is greater than **0**
4. Rerun `sonar-scanner`. The project shows **Failed**.

| Scope | Covers |
|---|---|
| Overall Code | everything, old and new |
| New Code | only code added/changed in the **New Code Period** (default 90 days / previous version) |

Assign a non-default gate per project: Project → **Project Settings → Quality Gate**.

> **The scanner does NOT fail on a red gate by default.** It uploads and
> exits 0. Add `-Dsonar.qualitygate.wait=true` to make it poll for the
> result and exit **1** on failure. That's what makes it a CI gate.

## 4. Custom rules (Quality Profiles)

Rule types and accuracy targets: **Code smell** and **Bug** aim for zero
FPs. **Vulnerability** aims for >80% true positives. **Security Hotspot**
is security-sensitive code that a human must review.

1. `$SONAR_URL/profiles` → find **Python** → ⚙ → **Extend** → `Django way`
   - **Extend** inherits from the parent, and parent changes flow down.
   - **Copy** makes an independent clone.
2. Open `Django way` → ⚙ → **Set as Default**
3. **Activate More** → Rules page → **Template** filter → *Show Templates
   Only* → **Track comments matching a regular expression** → **Create**:

| Field | Value |
|---|---|
| Name | `A1_Shell Injection_Vulnerabilities` |
| Description | It allows an attacker to execute OS commands on the server... |
| Regular expression | `(?i).*A1.*` (`(?i)` = case-insensitive) |
| Message | `Danger - Shell Injection detected` |

4. **Activate** → Severity **Blocker** → Activate.
5. Rescan. The log shows `Quality profile for py: Django way`.
   `$SONAR_URL/project/issues?resolved=false&severities=BLOCKER&id=Django`
   shows the hit on the `#A1 - Injection` comment in `misc.py`.

(This template rule matches **comments**, so it's a demo of custom rules,
not a real shell-injection detector.)

## 5. CI

**GitHub Actions** (`ci/github-actions.yaml`): SonarQube → *With GitHub
Actions* → create repo secrets `SONAR_TOKEN` and `SONAR_HOST_URL` (=
`$SONAR_URL`) → add the job → push → *Finish this tutorial*. The project
waits for its first analysis. `fetch-depth: 0` gives Sonar full history
for blame/new-code.

**GitLab CI** (`ci/gitlab-ci.yml`, bonus for the exam's CI system):
`sonarsource/sonar-scanner-cli` image with `entrypoint: [""]`, variables
`SONAR_HOST_URL`/`SONAR_TOKEN`, and `qualitygate.wait=true`.

## Notes
- `-Dsonar.login` is deprecated in newer scanners in favour of `-Dsonar.token`.
- Tokens: revoke at **My Account → Security** if leaked.
