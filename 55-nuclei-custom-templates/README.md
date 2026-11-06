# Lab 55: Hunting Vulnerabilities with Custom Nuclei Templates

## Goal
Deploy a deliberately vulnerable Flask API on the **sandbox** machine,
then write Nuclei templates for (a) missing security headers and (b) SQL
injection, and interpret the matches.

## 1. Deploy the target (on sandbox)

```bash
ssh root@$SANDBOX_HOST                     # yes to the prompt
apt update && apt install -y nginx         # reverse proxy to expose the app
git clone https://gitlab.practical-devsecops.training/pdso/vuln-api.git && cd vuln-api
docker build -t vuln-api .
docker run -d --name flask -p 5000:5000 vuln-api
curl localhost:5000                        # <h1>Practical DevSecOps TODOs API</h1>
```

The app only listens on localhost:5000. Expose it via nginx with
`nginx-default` from this lab (replace `LABID`) as
`/etc/nginx/sites-available/default`:

```bash
# on sandbox: paste the file content, or from the DevSecOps-Box:
#   labcat 55-nuclei-custom-templates/nginx-default | ssh root@$SANDBOX_HOST 'cat > /etc/nginx/sites-available/default'
systemctl restart nginx
exit
curl $SANDBOX_URL
```

(When the course writes this with an unquoted heredoc it escapes `\$host`.
Copying the file avoids that.)

## 2. Missing security headers

```bash
nuclei -u $SANDBOX_URL -t ../55-nuclei-custom-templates/templates/http_header.yaml
# [http-header:strict-transport-security] [http] [medium] ...
# [http-header:x-frame-options] [http] [medium] ...   ... 17 lines
nuclei -u $SANDBOX_URL -t ../55-nuclei-custom-templates/templates/http_header.yaml -j | jq '."matcher-name"'
```

Template anatomy:
- `matchers-condition: or`: each **named** matcher that fires produces its own result (`id:matcher-name`).
- `type: dsl` with `!regex('(?i)hsts', all_headers)` means "header absent"
  (case-insensitive), ANDed with "not a redirect" so 301/302s aren't
  counted.

Severity is a judgement call. Missing headers don't create vulnerabilities
themselves, but they make XSS/clickjacking easier to exploit. The course
rates them medium.

## 3. SQL injection

```bash
nuclei -u $SANDBOX_URL/api/v1/resources/todos/ -t ../55-nuclei-custom-templates/templates/sql-injection.yaml
# [sqli] [http] [high] .../todos/%20%22%22%7C0;              [null]
# [sqli] [http] [high] .../todos/%20%22%20OR%201%20=%201%20--%20-  [sqlite3.OperationalError: unrecognized token: ...]
# [sqli] [http] [high] .../todos/%20OR%201=1                  [sqlite3.OperationalError: near "OR": syntax error ...]
# [sqli] ... ORDER BY / GROUP BY                               [sqlite3.OperationalError ...]
```

- Lines 2–5: the payloads broke the SQL and the Werkzeug debugger leaked
  `sqlite3.OperationalError`, so the input reaches the query unsanitised.
  That's a **real SQLi indicator**, plus `DEBUG` mode is enabled.
- Line 1 `[null]`: the regex alternation includes `null`, which matches
  normal JSON. That's noise from the course template.
  `templates/sql-injection-strict.yaml` uses a **matcher** on real DB
  errors and an extractor only for the message:

```bash
nuclei -u $SANDBOX_URL/api/v1/resources/todos/1 -t ../55-nuclei-custom-templates/templates/sql-injection-strict.yaml
```

## Notes
- Validate templates: `nuclei -validate -t templates/`.
- Matchers decide **whether** something is a finding. Extractors pull
  **data** out of the response. An extractor-only template turns every
  regex hit into a finding.
- Only point fuzzing/injection templates at systems you own.
