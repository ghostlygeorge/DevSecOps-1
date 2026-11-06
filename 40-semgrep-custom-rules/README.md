# Lab 40: Writing Custom Semgrep Rules

## Goal
Write rules with the ellipsis operator, metavariables, and
`pattern-not` / `pattern-inside`, then solve the course's SQL-injection
rule challenge.

## Setup
```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install semgrep==1.30.0
```

## Pattern syntax

| Construct | Example | Matches |
|---|---|---|
| Ellipsis `...` | `os.system(...)` | `os.system("x")`, `os.system(cmd)`, any arguments |
| Metavariable `$X` | `$X = $Y` | any assignment, binding X and Y |
| | `$X.objects.get` | `Project.objects.get`, `User.objects.get`, ... |
| String ellipsis `"..."` | `os.system("...")` | only literal strings |

```bash
semgrep --lang python -e '$X = $Y' .
semgrep --lang python -e '$X.objects.get' .
```

## Rule schema

Required: `id`, `message`, `severity` (INFO/WARNING/ERROR), `languages`,
plus one of `pattern` | `patterns` (AND) | `pattern-either` (OR) |
`pattern-regex`.

Inside `patterns`/`pattern-either`:

| Key | Logic |
|---|---|
| `pattern-not` | NOT. Remove matches of this. |
| `pattern-inside` | keep only matches inside this block |
| `pattern-not-inside` | keep only matches outside this block |
| `metavariable-regex` | constrain a metavariable's text with a regex |
| `pattern-where-python` | legacy Python filter (removed in modern Semgrep) |

## Rules in this lab (`rules/`)

```bash
semgrep --lang python -f ../40-semgrep-custom-rules/rules/command_injection.yaml .
#  taskManager/misc.py 33: os.system("mv " + uploaded_file.temporary_file_path() + ...)
semgrep --lang python -f ../40-semgrep-custom-rules/rules/find_project_db_get_call.yaml .
#  taskManager/views.py 89: project = Project.objects.get(pk=projectid)
```

- `command_injection.yaml`: `os.system(...)` **but not** `os.system("...")`.
  Hardcoded commands aren't injectable.
- `find_project_db_get_call.yaml`: `Project.objects.get(...)` **only inside**
  `def $FUNC(request): ...`. When the rule is written with an unquoted heredoc,
  escape `\$FUNC`. Copying the file avoids that.

(`-f` = `--config`.)

## Challenge: detect the SQL injection in `views.py upload()`

```python
curs.execute(
    "insert into taskManager_file ('name','path','project_id') values ('%s','%s',%s)" %
    (name, upload_path, project_id))
```

Solution: `rules/sqli_challenge_solution.yaml`

```bash
semgrep -f ../40-semgrep-custom-rules/rules/sqli_challenge_solution.yaml .
#  taskManager/views.py 183-185 python-raw-sql-string-building
```

It catches `%`-formatting, concatenation, `.format()`, f-strings, and
queries built in a variable first. It excludes the safe
`execute("...", [params])` form.

## Testing rules properly
```bash
semgrep --test rules/          # runs rules against annotated test files: # ruleid: <id> / # ok: <id>
semgrep --validate --config rules/
```
Playground: <https://semgrep.dev/playground>
