# Lab 20: SCA for JavaScript with Retire.js

## Goal
Find vulnerable JavaScript libraries (both vendored `.js` files and npm
dependencies), understand what `--severity` **actually** does, mark false
positives with `.retireignore.json`, and run it in GitLab CI.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
bash ../20-sca-retirejs/install-node.sh      # Node 20 via NodeSource
npm install -g retire@5.0.0
retire --help
```

## 1. Scan before and after `npm install`

```bash
cat package.json
retire --outputformat json --outputpath no-npm-install-retire-output.json
jq . no-npm-install-retire-output.json        # only vendored JS (jquery 1.8.3 etc.)

npm install                                    # "104 vulnerabilities" from npm audit
retire --outputformat json --outputpath retire_output.json
jq . retire_output.json                        # now also npm components (tinymce, lodash...)
```

Retire finds vendored `.js` files by hash/signature, but needs
`node_modules` to see npm dependencies. Old versions refused to run without
it. 5.x scans silently and gives incomplete results. **Always `npm install`
first.**

## 2. `--severity` is a failure threshold, not a filter

```bash
retire --severity critical --outputformat json --outputpath retire_output.json; echo $?   # 0
retire --severity medium   --outputformat json --outputpath retire_output.json; echo $?   # 13
jq '[.data[].results[].vulnerabilities[]?.severity] | group_by(.) | map({(.[0]): length}) | add' retire_output.json
```

The report still contains low/medium/high/critical findings either way.
`--severity X` only decides whether the **exit code** is non-zero (13 by
default, change it with `--exitwith`). That's by design. Every tool
differs, so check before assuming.

## 3. Challenges

**#1: non-zero only for high severity**
```bash
retire --severity high --outputformat json --outputpath retire_output.json
```

**#2: mark all high-severity issues as FP, save to `/webapp/retire_output.json`**
```bash
# which components carry a high finding?
jq '.data[].results[] | select(.vulnerabilities[]?.severity=="high") | .component,.version' retire_output.json
cp ../20-sca-retirejs/retireignore.json /webapp/.retireignore.json     # or write it with a heredoc
retire --severity high --ignorefile .retireignore.json --outputformat json --outputpath retire_output.json
jq '.data[].results[] | select(.vulnerabilities[]?.severity=="high") | .component,.version' retire_output.json   # empty
```

`.retireignore.json` entries are `{component, version, justification}`.
Omit `version` to ignore every version. There's also a path-based
`.retireignore` text file for whole directories.

## 4. GitLab CI
`ci/gitlab-ci.yml` adds `oast-frontend` to the test stage on
`node:alpine3.10`. The job fails with exit 13 (findings ≥ high), which is
the expected DevSecOps-friendly behaviour. `allow_failure: true` keeps the
pipeline going (orange "!"), and `artifacts: when: always` keeps the report
for DefectDojo.

## Notes
- `npm install -g retire` in CI is unpinned. Pin `retire@5.0.0` for reproducibility.
- For DefectDojo use scanner name `Retire.js Scan`.
- `--outputformat cyclonedx` gives an SBOM as a side benefit.
