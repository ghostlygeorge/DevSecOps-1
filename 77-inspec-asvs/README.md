# Lab 77: Verifying OWASP ASVS Controls with InSpec

## Goal
Use InSpec's `http` resource to check **web application** requirements
from OWASP ASVS 4.0 §14.4 (HTTP security headers). Compliance as Code
isn't limited to OS configuration.

## Run

```bash
bash ../71-inspec-basics/install-inspec.sh
mkdir inspec-asvs && cd inspec-asvs
inspec init profile asvs --chef-license accept
cp ../77-inspec-asvs/profile/controls/example.rb asvs/controls/example.rb
cp ../77-inspec-asvs/profile/inspec.yml asvs/inspec.yml && labify asvs/inspec.yml
inspec check asvs          # Controls: 6
inspec exec asvs
# ✔ ASVS-14.4.1 Safe character set
# × ASVS-14.4.2 Content-Disposition attachment   got: (empty)
# × ASVS-14.4.3 CSP  expected nil not to include ... (header missing)
# × ASVS-14.4.4 X-Content-Type-Options
# × ASVS-14.4.5 HSTS
# × ASVS-14.4.6 Referrer-Policy
# Profile Summary: 1 successful control, 5 control failures
```

The `http` resource runs **from the machine running InSpec**, so
`inspec exec asvs` locally is enough. No `-t` is needed for a URL.
Point it elsewhere with `--input target_url=https://example.com`.
(The course hardcodes the URL in each control. This version uses an input.)

| ASVS | Header | Expected |
|---|---|---|
| 14.4.1 | Content-Type | `text/html; charset=utf-8` |
| 14.4.2 | Content-Disposition | `attachment` (for API/download responses) |
| 14.4.3 | Content-Security-Policy | present, no unsafe-inline/eval/`*` |
| 14.4.4 | X-Content-Type-Options | `nosniff` |
| 14.4.5 | Strict-Transport-Security | `max-age=...` |
| 14.4.6 | Referrer-Policy | restrictive |

## Fixing it (nginx on prod)
```nginx
add_header X-Content-Type-Options "nosniff" always;
add_header Strict-Transport-Security "max-age=15724800; includeSubDomains" always;
add_header Referrer-Policy "no-referrer" always;
add_header Content-Security-Policy "default-src 'self'" always;
```

## Notes
- ASVS-14.4.3's `should_not include` on a **missing** header raises
  `expected nil not to include ...`. Add `its('headers.content-security-policy') { should_not be_nil }`
  first so the failure reads clearly.
- The same checks as Nuclei's header template ([lab 55](../55-nuclei-custom-templates))
  and ZAP rules 10035/10038/10021. InSpec gives you pass/fail compliance
  evidence mapped to a standard, which auditors like.
- Can run in CI like any profile. Point it at the staging URL.
