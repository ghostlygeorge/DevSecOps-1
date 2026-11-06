# Lab 52: Controlling ZAP Results with the Config File (IGNORE / FAIL / OUTOFSCOPE)

## Goal
Turn the dev team's triage decisions into policy:
1. **FAIL** the scan if 10035 (HSTS) and 10036 (Server header) persist
2. **Ignore** the 10099 false positive
3. **Ignore all `.css`** URLs for now

The progress file ([lab 51](../51-dast-zap-progress-file)) only relabels.
The config file changes **outcomes**.

## 1. Generate a config from a scan

```bash
docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 \
  zap-baseline.py -t $PROD_URL -g default.conf
cat default.conf          # every rule seen, all set to WARN
```

The image is auto-pulled if missing, so no `docker pull` is needed.

## 2. Edit it (`nano default.conf`)

Line format: `<rule-id><TAB><WARN|FAIL|IGNORE|INFO|OUTOFSCOPE><TAB><name / message / url-regex>`

```
10035	FAIL	(Strict-Transport-Security Header) [HIGH PRIORITY]
10036	FAIL	(HTTP Server Response Header) [HIGH PRIORITY]
10099	OUTOFSCOPE	https://prod-<id>.lab.practical-devsecops.training/taskManager/tutorials/injection/
*	OUTOFSCOPE	.*\.css$
```

A ready-made version is in `default.conf` here (`labify default.conf`).

> **Tabs, not spaces.** With spaces you get
> `Failed to load config file /zap/wrk/default.conf not enough values to unpack (expected 3, got 1)`.
> Check with `cat -A default.conf`: tabs show as `^I`.

## 3. Scan with it

```bash
docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 \
  zap-baseline.py -t $PROD_URL -c default.conf
# PASS: Source Code Disclosure [10099]           <- its only instance was out of scope
# FAIL-NEW: Strict-Transport-Security Header Not Set [10035] x 12 [HIGH PRIORITY]
# FAIL-NEW: Server Leaks Version Information ... [10036] x 11 [HIGH PRIORITY]
echo $?     # 1 -> the pipeline now FAILS on these two rules
```

Only show FAILs:
```bash
docker run ... zap-baseline.py -t $PROD_URL -c default.conf -l FAIL     # add -s to hide example URLs
```

Out-of-scope a whole host for one rule (try it):
```
10036	OUTOFSCOPE	https://prod-<id>.lab.practical-devsecops.training
```

## 4. Does the config affect the JSON report?

```bash
docker run ... zap-baseline.py -t $PROD_URL -c default.conf -J zap-output.json
vi zap-output.json     # /10099  (vi copes with very long lines better than nano)
```

The JSON report still contains everything (riskdesc, desc, solution,
reference, cweid...). The config only changes the **console result and
exit code**.

> **Course erratum:** the course's "check JSON" command passes `-g default.conf`
> (generate), which **overwrites your edited config** with all-WARN.
> Use `-c` there.

## IGNORE vs OUTOFSCOPE
| | IGNORE | OUTOFSCOPE |
|---|---|---|
| Granularity | the whole **rule** | rule × **URL regex** (or `*` for all rules) |
| Effect | rule still runs, results reported as IGNORE, never fails | matching URLs are dropped for that rule. If nothing is left, the rule PASSes. |
| Use for | rules irrelevant to the app | specific false-positive URLs, static assets |

## Recap
- `-g file` generates, `-c file` uses, `-l LEVEL` filters the display.
- Only WARN → IGNORE / FAIL / INFO / OUTOFSCOPE are valid states.
- URL filtering needs regex. Tabs are mandatory.
- `-u URL` loads the config from a URL (a shared org policy).
- Combine with the progress file (`-c` + `-p`) for full tracking.
