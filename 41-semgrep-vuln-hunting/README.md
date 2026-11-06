# Lab 41: Hunting Vulnerabilities with Semgrep

## Goal
Hunt for CSRF, security misconfiguration, and open redirects in a Django
app with targeted rules, and use the ported **Bandit** ruleset.

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
pip3 install semgrep==1.31.0
R=../41-semgrep-vuln-hunting/rules
```

## CSRF

```bash
semgrep -f $R/csrf_hunting.yaml .
# possible-csrf  views.py:739 @csrf_exempt reset_password / :779 forgot_password / :813 change_password
```

Django is CSRF-vulnerable when views use `@csrf_exempt` or
`django.middleware.csrf.CsrfViewMiddleware` is missing from
`MIDDLEWARE_CLASSES`. Rule 1 finds the exempt functions. Rule 2 flags a
middleware tuple that lacks the CSRF middleware (`...` before and after it
means "anywhere in the tuple").

`change_password` being CSRF-exempt is especially bad: an attacker page
can change a logged-in victim's password.

## Misconfiguration (OWASP A6/A05)

```bash
semgrep -f $R/debug_enable.yaml .        # settings.py:28 DEBUG = True
```

`DEBUG=True` in production leaks stack traces, settings, and SQL. The
rule's `metadata` block carries CWE/OWASP/references through to reports and
DefectDojo.

## Ported tool rulesets

```bash
semgrep --config "p/bandit" .
# dangerous-system-call  misc.py:33
# formatted-sql-query    views.py:183
# Ran 61 rules ... 2 findings
```

Semgrep's team ported Bandit, gosec, nodejsscan, findsecbugs, and
eslint-plugin-security to Semgrep rules.

**Did it miss anything Bandit finds?** Yes. Bandit reports more findings
on this repo (hardcoded passwords, `mark_safe`, MD5...). The `p/bandit`
pack only ports a **subset** of Bandit's tests, and Semgrep's are
pattern-based where Bandit has custom AST logic for some checks. Ported
packs are not equivalent to the original tool. Run both, or compare
results before replacing one.

## Challenge: insecure redirect

```bash
semgrep -f $R/insecure_redirect.yaml .
#  CWE-601 Insecure Redirect  views.py:369 return redirect(request.GET.get('redirect', '/taskManager/'))
```

`request.$M.get(...)` matches `request.GET`, `request.POST`, ... with any default.

## Notes
- For real taint tracking (source → sink) use `mode: taint` with
  `pattern-sources` / `pattern-sinks`. It catches cases where the user input
  is first stored in a variable, which plain patterns miss.
