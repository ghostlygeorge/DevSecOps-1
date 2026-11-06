# Lab 25: Fixing SCA Findings with OSV-Scanner

## Goal
Use Google's **OSV-Scanner** to find vulnerable Python and npm
dependencies, **actually fix them** (upgrade direct deps, trace transitive
ones with `npm list`), work offline with a local DB, ignore false
positives, and embed it in GitLab CI.

## 1. Prepare: a lockfile is mandatory for npm

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
apt update && apt install npm -y
npm install          # creates package-lock.json (ignore the vulnerability warnings for now)
ls                   # ... package-lock.json ...
```

| File | Precision | Scannable by OSV? |
|---|---|---|
| `requirements.txt` | exact pins (`Django==3.0`), like a precise shopping list | yes |
| `package.json` | ranges (`^4.0.0`, "any kind of apple") | **no** |
| `package-lock.json` | exact resolved tree | yes |

## 2. Install

```bash
wget -O /usr/bin/osv-scanner https://github.com/google/osv-scanner/releases/download/v1.4.0/osv-scanner_1.4.0_linux_amd64 && chmod +x /usr/bin/osv-scanner
osv-scanner --help     # -L lockfile, -S sbom, -D docker image, -r recursive, --format json, --config
```

## 3. Python: scan → fix → rescan

```bash
osv-scanner -L requirements.txt        # ~18 GHSA/PYSEC rows for django 3.0
cat > requirements.txt <<EOL
Django==5.0
EOL
osv-scanner -L requirements.txt        # down to 2 (5.0 has its own later CVEs; pick the latest patch in reality)
```

## 4. npm: fix transitive dependencies

```bash
osv-scanner -L package-lock.json       # adm-zip 0.4.4, babel-traverse, bl, bson, ... yargs-parser 2.4.1

npm list adm-zip                       # who pulls it in?
#   owasp-nodejs-goat@1.3.0 └─┬ selenium-webdriver@2.53.3 └── adm-zip@0.4.4
npm install selenium-webdriver@latest --save
npm list selenium-webdriver            # 4.21.0
osv-scanner -L package-lock.json       # adm-zip gone

npm list yargs-parser                  # grunt-if > grunt-contrib-nodeunit > nodeunit > tap > nyc > yargs-parser 2.4.1
npm install grunt-if@latest --save
npm list yargs-parser                  # 21.1.1
osv-scanner -L package-lock.json       # yargs-parser gone
```

You can't upgrade a transitive dependency directly. Find the **direct**
dependency that pulls it in (`npm list <pkg>`) and upgrade that. If the
parent hasn't released a fix, use npm `overrides` in package.json to force
the child version.

## 5. Offline / local DB

```bash
osv-scanner --experimental-local-db .     # downloads per-ecosystem DBs to ~/.cache/osv-scanner/<eco>/all.zip
zipinfo /root/.cache/osv-scanner/npm/all.zip | tail
osv-scanner --experimental-offline .      # uses the cached DBs only, no network
```

| Option | Network | Use |
|---|---|---|
| `--experimental-local-db` | yes: downloads/updates DB, then scans locally | faster repeated scans, no per-package API calls |
| `--experimental-offline` | **none**, cached DB only | air-gapped runners |

(In osv-scanner v2 these became `--offline-vulnerabilities` / `--download-offline-databases`.)

## 6. Ignore false positives

```bash
cp ../25-sca-osv-scanner/osv-scanner.toml /webapp/config.toml
osv-scanner --config=/webapp/config.toml -L requirements.txt
# PYSEC-2024-47 and 1 alias have been filtered out because: false positive
# ... No vulnerabilities found
```

> **Course erratum:** `osv-scanner--config=...` (no space) is a typo.

If you name the file `osv-scanner.toml` and place it beside the scanned
file, it's picked up automatically.

## 7. GitLab CI
`ci/gitlab-ci.yml`: the job builds osv-scanner with `go install` on a
golang alpine image, runs `npm install` to get a lockfile, then
`osv-scanner --json . > osv-report.json`. It fails (exit 1) and
`allow_failure: true` keeps it non-blocking.

## Notes
- `go install ...@v1` floats to the latest v1. Pin `@v1.4.0` or download
  the release binary for reproducibility.
- OSV aggregates GHSA, PyPI (PYSEC), Go, RustSec, OSS-Fuzz, and more. One
  vulnerability often appears under several IDs (aliases), which is why one
  ignore filtered "1 alias" too.
