# Lab 27: SCA with Semgrep Supply Chain (Reachability Analysis)

## Goal
Use `semgrep ci --supply-chain` to find vulnerable dependencies **and**
whether your code actually calls the vulnerable function (reachability),
which is how you prioritise SCA noise.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install semgrep==1.31.0
semgrep --help        # ci | login | scan | show | publish | lsp ...
# If every command warns "urllib3 ... or chardet ... doesn't match a supported version":
pip3 install --upgrade requests
```

## Run

```bash
semgrep ci --supply-chain        # "run `semgrep login` before using `semgrep ci` or set `--config`"
semgrep login                    # open the URL, sign in with a PERSONAL GitHub/GitLab account, approve the token
cat /root/.semgrep/settings.yml  # token stored here
semgrep ci --supply-chain
```

## Reading the output

```
 SUPPLY CHAIN RULES
 Ecosystem  Rules  Files  Lockfiles         Analysis      Rules
 Pypi       4531   21     requirements.txt  Basic         4286
                                            Reachability   245
```

- **Lockfile**: the file listing exact dependency versions (`requirements.txt`, `package-lock.json`, `go.mod`, `Gemfile.lock`, `poetry.lock`, `Pipfile.lock`, `yarn.lock`, `pnpm-lock.yaml`, `gradle.lockfile`, Maven dep tree, `Cargo.lock`, `composer.lock`, `packages.lock.json`).
- **13 Reachable findings**: CVE-2021-35042 (Django `QuerySet.order_by` SQLi).
  Semgrep found the actual `order_by(...)` call sites in `forms.py` and
  `views.py`. The vulnerable version **and** the vulnerable code pattern
  both match, so **fix these first**.
- **4 Undetermined findings**: the version is vulnerable, but there's no
  reachability rule or no matching use (e.g. CVE-2021-44420, CVE-2021-31542).
  Still upgrade, but with lower urgency.

| | Classic SCA (Safety, OSV) | Semgrep Supply Chain |
|---|---|---|
| Input | lockfile | lockfile **+ source code** |
| Answers | "is a vulnerable version present?" | "...and is the vulnerable code path used?" |
| Noise | high | much lower for reachable-only triage |

## Save the output

```bash
semgrep ci --help | grep "Output formats" -A9     # --json --sarif --gitlab-sast --junit-xml --text --emacs --vim
semgrep ci --supply-chain --output semgrep-sca-output.json --json
ls -l semgrep-sca-output.json
jq '[.results[] | {cve: .extra.metadata["sca-vuln-database-identifier"], reach: .extra.sca_info.reachable}]' semgrep-sca-output.json | head
```

Then attach it as a CI artifact (with `SEMGREP_APP_TOKEN` as a CI variable
instead of `semgrep login`).

## Notes
- `semgrep ci` uploads results to Semgrep Cloud Platform. Don't do this
  with proprietary code under a personal account.
- `semgrep ci` exits 1 only for **blocking** findings (set by your cloud
  policy). The course run exits 0 ("No blocking findings").
