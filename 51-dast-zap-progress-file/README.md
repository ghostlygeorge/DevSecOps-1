# Lab 51: Tracking DAST Issues with the ZAP Progress File

## Goal
Triage ZAP baseline alerts (true vs false positive) by verifying them by
hand, then use a **progress file** so issues already being worked on show
as `WARN-IN_PROGRESS` with a tracking link, and new problems stand out.

Passive scanning only observes the traffic the spider generates. It never
alters requests, so it's safe and fast.

## 1. Baseline scan
```bash
docker run --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t $PROD_URL
# ... FAIL-NEW: 0 FAIL-INPROG: 0 WARN-NEW: 17 WARN-INPROG: 0 ... PASS: 48
```

## 2. False Positive Analysis
Alert docs: `https://www.zaproxy.org/docs/alerts/<id>/` (Summary, Solution, Other Info, Reference, Code).

| Alert | Verify | Verdict |
|---|---|---|
| **10035** Strict-Transport-Security Header Not Set ([10035-1](https://www.zaproxy.org/docs/alerts/10035-1/)) | `curl -I $PROD_URL`: no `strict-transport-security` header | **Real** |
| **10036** Server Leaks Version via `Server` header ([10036-2](https://www.zaproxy.org/docs/alerts/10036-2/)) | `curl -I $PROD_URL/static/taskManager/css/backend/bootstrap-reset.css` → `server: nginx/1.18.0 (Ubuntu)` | **Real** |
| **10099** Source Code Disclosure - SQL | open `$PROD_URL/taskManager/tutorials/injection/`: SQL is shown on purpose (it's a tutorial page of an intentionally vulnerable app) | **False positive in context** |

`curl -I` sends a HEAD request, which returns headers only. It's like
reading a book's table of contents without reading the pages.

Fixes: nginx `add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;`
and `server_tokens off;`. Document findings and discuss them with the devs.

## 3. Progress file
Format (`progress-file.json`, `labify` it):

| Field | Meaning |
|---|---|
| `id` | ZAP alert/plugin ID |
| `name` | description |
| `state` | `inprogress` (being addressed, not yet resolved) |
| `link` | where it's tracked (DefectDojo finding, Jira, a note) |

```bash
cp ../51-dast-zap-progress-file/progress-file.json . && labify progress-file.json
docker run -it -v $(pwd):/zap/wrk softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t $PROD_URL -p progress-file.json
# WARN-IN_PROGRESS: Strict-Transport-Security Header Not Set [10035] x 13
#      Progress link: https://dojo-<id>.../finding/3
# ...
# FAIL-NEW: 0 FAIL-INPROG: 0 WARN-NEW: 12 WARN-INPROG: 4 INFO: 0 IGNORE: 0 PASS: 48
```

`-v $(pwd):/zap/wrk` is required: `-p` paths resolve relative to `/zap/wrk`.

Result: `WARN-NEW` → `WARN-IN_PROGRESS`, WARN-NEW 17 → 12, WARN-INPROG 0 → 4.

Save the output too:
```bash
docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 \
  zap-baseline.py -t $PROD_URL -p progress-file.json -J zap-output.json
```

## Notes
- The progress file **doesn't hide** anything. It just relabels known
  issues. To exclude or escalate, use the config file ([lab 52](../52-dast-zap-config-file)).
- Combining progress links with DefectDojo finding URLs gives a closed
  loop: scan → triage in Dojo → progress file references Dojo.
