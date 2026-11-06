# Lab 44: Code Quality Analysis with Pylint

## Goal
Run **pylint** for code quality (not primarily security), read its
message categories and score, and cut noise with `.pylintrc`.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install pylint
pylint --help          # --disable/--enable, --fail-under, --exit-zero, -f json, --rcfile, --generate-rcfile
```

## Scan

```bash
pylint taskManager/*.py
# taskManager/forms.py:18:0: E0401: Unable to import 'django' (import-error)
# taskManager/views.py:48:12: R1705: Unnecessary "else" after "return" (no-else-return)
# ...
# Your code has been rated at 6.37/10
pylint taskManager/*.py -f json | tee output.json
jq '[.[].type] | group_by(.) | map({(.[0]): length}) | add' output.json
```

| Letter | Category |
|---|---|
| C | convention (style, naming, docstrings) |
| R | refactor (code smells) |
| W | warning (unused variables/args/imports, dangerous defaults) |
| E | error (probable bugs) |
| F | fatal |

## Reduce false positives

```bash
cp ../44-code-quality-pylint/pylintrc .pylintrc
pylint taskManager/*.py
# Your code has been rated at 8.41/10 (previous run: 6.37/10, +2.03)
```

`import-error` here is a true FP: Django isn't installed in the scanning
env. Install `requirements.txt` in a venv and run pylint inside it, and
those go away for real.

## CI gating
- `--fail-under=8` exits non-zero when the score drops below 8.
- The exit code is a **bitmask** (1 fatal, 2 error, 4 warning, 8 refactor,
  16 convention, 32 usage). `--exit-zero` to report only.
- Security-relevant pylint messages exist (`W0102` dangerous default,
  `W0123` eval-used, `W1510` subprocess without check), but use Bandit/Semgrep
  for security SAST.
