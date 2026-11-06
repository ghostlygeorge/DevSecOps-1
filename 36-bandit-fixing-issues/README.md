# Lab 36: Fixing the Issues Reported by Bandit

## Goal
Go from a SAST report to **actual code fixes** in a vulnerable Flask API
(dvpa-api): unsafe YAML deserialisation, SQL injection, weak hashing, and
hardcoded secrets. Verify each fix with a rescan.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/dvpa-api webapp && cd webapp
pip3 install bandit==1.7.4
bandit -r .        # 13 issues: 2 hardcoded passwords, MD5, yaml.load, 8 SQLi candidates
```

## Fix 1: insecure deserialisation (B506)

```bash
sed -n 245,250p flaskblog/blogapi/dashboard.py       # yaml.load(import_data)
sed -i 's/yaml\.load(import_data)/yaml.safe_load(import_data)/' flaskblog/blogapi/dashboard.py
bandit -r .        # High-confidence count 4 -> 3, the yaml.load issue is gone
```

`yaml.load` without a safe Loader can instantiate arbitrary Python objects
from YAML tags (`!!python/object/apply:os.system`), which is RCE.
`safe_load` only builds plain types. (CVE-2020-1747 / CVE-2017-18342 class.)

## Fix 2: SQL injection (B608)
Parameterised queries (parameter binding) are the correct fix. See
**`fixes.md`** for before/after of all 7 call sites, including the `LIKE`
query.

```bash
# auth.py line 14
sed -i "14s/.*/    cur.execute(\"SELECT * FROM users WHERE email=%s AND password=%s\", [username, hashsed_password])/" flaskblog/auth.py
bandit -r .
```

### "No change in the output" — what's really happening
The course replaces line 14 but **keeps the `f` prefix**:
`cur.execute(f"SELECT ... email=%s ...", [...])`. Bandit's B608 is a
heuristic that flags SQL-looking **f-strings / concatenation / `%` / `.format`**.
The query *is* now safe, but the f-string still trips the rule, so the
course concluded "False Positive". Drop the `f` and the finding
disappears, because the heuristic no longer matches. Lesson: rescanning
proves the tool is quiet, not that the code is safe, and vice versa.
Read the code.

## Challenge
Fix **all** SQL injection issues, re-scan, and mark leftovers as FP via a
baseline ([lab 35](../35-bandit-false-positive-analysis)). After applying
`fixes.md`:

```bash
bandit -r . | grep -c B608      # 0
bandit -r . -f json | jq '[.results[].test_id] | group_by(.) | map({(.[0]): length}) | add'
# remaining: B303 (md5) x3, B105 x2. Those need design changes (fixes.md sections 3-4)
```

## Notes
- Re-run the app and its tests after every fix. A "fix" that breaks the
  login is worse than a finding.
- `%s` is the placeholder for MySQLdb/psycopg2. sqlite3 uses `?`. The
  binding mechanism is the same.
