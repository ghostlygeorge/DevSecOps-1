# Lab 35: False Positive Analysis (FPA) with Bandit's Baseline

## Goal
Decide which SAST findings are **real**, then suppress only the false
positives in a way that's reviewable, automatable, and DefectDojo-friendly:
a **baseline file**, not `# nosec`.

## Setup and scan

```bash
git clone https://gitlab.practical-devsecops.training/pdso/dvpa-api && cd dvpa-api
pip3 install bandit==1.7.4
bandit -r .
# Total issues (by severity): Low 2, Medium 11, High 0  -> 13 total
```

## Two ways to do FPA
1. **Read the source code** (this lab)
2. Exploit the finding dynamically

### Worked analysis

| Finding | Code | Verdict |
|---|---|---|
| B608 `dashboard.py:100` | `f"UPDATE users SET ... WHERE id = {request.args.get('uid')}"` | **True positive**: user input interpolated into SQL |
| B608 `dashboard.py:133` | `cur.execute(f"INSERT ... VALUES (%s, %s, %s, %s)", [body, slug, ...])` | **False positive**: `%s` placeholders + param list = parameterised query. The `f` prefix just triggers the heuristic. |
| B506 `dashboard.py:248` | `yaml.load(import_data)` | **True positive**: unsafe deserialisation (CVE-2020-1747 class) |
| B303 `auth.py:13` | `hashlib.md5(password...)` | **True positive**: unsalted MD5 for passwords |
| B105 `config.py:13` | `password = 'secret'` | context-dependent. The course treats it as the example FP. |

## Why not `# nosec`?
- You have to grep the whole codebase to list FPs.
- You can't mark them programmatically in DefectDojo or other VM tools.
- You can't build custom fail criteria (maturity levels 3–4).

## Baseline workflow

```bash
bandit -r . -f json | tee baseline.json                # 1. dump everything
# 2. edit baseline.json: DELETE every true positive; keep only false positives
#    (if you keep everything, every finding is suppressed. Don't.)
bandit -r . -f json | jq '.results | length'           # 13
cp ../35-bandit-false-positive-analysis/baseline-config-secret.json baseline.json
bandit -r . -f json -b baseline.json | jq '.results | length'   # 12
```

The baseline plays the same role as `.retireignore.json` (lab 20),
`brakeman.ignore` (lab 37), DC suppression XML (lab 21), and `.secrets.baseline` (lab 30).

## Challenges

**#1: baseline with only the `dashboard.py:132/133` SQLi as FP, saved to `/dvpa-api/baseline.json`**
```bash
cp ../35-bandit-false-positive-analysis/baseline-challenge.json /dvpa-api/baseline.json
# or generate it instead of hand-editing:
../35-bandit-false-positive-analysis/make-baseline.sh B608:./flaskblog/blogapi/dashboard.py:133
```
Why it's FP: `%s` placeholders make the DB driver bind parameters; nothing
is string-concatenated.

**#2: prove it's gone**
```bash
bandit -r . -f json -b baseline.json
bandit -r . -f json -b baseline.json | grep "132             cur.execute"    # no output
```

## Notes
- Bandit matches baseline entries on filename + test + **code snippet**, not
  only line numbers, so small line shifts don't resurrect FPs. Changing the
  code itself does, which is what you want.
- Further reading: "The myth of false positives in SAST" (dev.to), and the
  Netsparker, Synopsys, and Contrast whitepapers on FP accuracy.
