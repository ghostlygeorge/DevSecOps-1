# Lab 42: Fixing the Issues Reported by Semgrep

## Goal
Run custom rules against the dvpa Flask blog, fix insecure deserialisation
(optionally with **autofix**) and SQL injection, and watch the count drop.

```bash
git clone https://gitlab.practical-devsecops.training/pdso/dvpa webapp && cd webapp
pip3 install semgrep==1.31.0
cp ../42-semgrep-fixing-issues/semgrep_rules.yaml .
semgrep -f semgrep_rules.yaml .
# blog/auth.py:14             possible-sqli
# blog/dashboard/post.py:204  avoid-pyyaml-load  (Autofix -> yaml.safe_load(import_data))
# blog/dashboard/post.py:60   possible-sqli
# blog/user.py:57             possible-sqli
# blog/views.py:37, :68       possible-sqli
# Ran 2 rules on 15 files: 6 findings
```

The SQLi rule: any `$X.execute(...)` **except** with a parameter list or a
constant string. The YAML rule only fires in files that `import yaml`
(`pattern-inside`) and has a `fix:` template.

## Fix 1: deserialisation

```bash
sed -i '204s/yaml\.load(import_data)/yaml.safe_load(import_data)/' blog/dashboard/post.py
# or let semgrep apply the rule's fix: template:
semgrep -f semgrep_rules.yaml --autofix .          # --dryrun to preview
semgrep -f semgrep_rules.yaml .                    # 6 -> 5
```

## Fix 2: SQLi in `blog/auth.py:14`

```python
cur.execute(f"SELECT * FROM users WHERE email=%s AND password=%s", [username, hashsed_password ])
```

```bash
semgrep -f semgrep_rules.yaml .                    # 5 -> 4
```

Semgrep accepts this line even with the leftover `f` because the rule
looks at the call shape (`execute(..., [...])`), unlike Bandit's string
heuristic in [lab 36](../36-bandit-fixing-issues). Drop the `f` anyway.

## Remaining (your turn)
Apply the same parameter-binding pattern to `post.py:60`, `user.py:57`,
and `views.py:37`/`:68`. The LIKE query becomes
`cur.execute("SELECT * FROM posts WHERE title LIKE %s", ["%" + query + "%"])`.
Target: `Ran 2 rules on 15 files: 0 findings`.
