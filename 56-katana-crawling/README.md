# Lab 56: Expanding the Attack Surface with Katana

## Goal
Crawl/spider an app with ProjectDiscovery's **Katana** to enumerate
endpoints. Every endpoint found is one more thing for DAST and fuzzing to
test.

## Install

```bash
wget https://github.com/projectdiscovery/katana/releases/download/v1.0.3/katana_1.0.3_linux_amd64.zip
unzip katana_1.0.3_linux_amd64.zip && mv katana /usr/bin/
katana --help
```

| Group | Flags |
|---|---|
| Input | `-u URL` / `-list file` |
| Config | `-d depth` (3), `-jc` parse JS for endpoints, `-kf robotstxt,sitemapxml`, `-ct 5m`, `-aff` auto-fill forms, `-H` headers/cookies (authenticated crawl) |
| Headless | `-hl`, `-xhr` |
| Scope | `-cs`/`-cos` in/out-of-scope regex, `-fs rdn\|fqdn\|dn`, `-ns` |
| Filter | `-f url\|path\|qurl\|...`, `-em/-ef` extensions, `-mr/-fr` regex |
| Rate | `-c`, `-p`, `-rl`, `-rd` |
| Output | `-o`, `-j`, `-silent` |

## Crawl

```bash
katana -u $PROD_URL/
# .../static/taskManager/css/font-awesome.css
# .../taskManager/login
# .../taskManager/tutorials/  ... /injection/ /xss/ /csrf/ /idor/ /redirects/ ...
# .../taskManager/forgot_password
# .../static/taskManager/js/jquery-1.8.3.min.js
```

The course output shows the `devsecops-box-<id>` URL because the
screenshot came from a different run. Point it at your prod URL.

## More useful variants

```bash
katana -u $PROD_URL -jc -kf all -d 5 -silent -o all-urls.txt       # deeper + JS + robots/sitemap
katana -u $PROD_URL -f qurl -silent                                # only URLs with query params (fuzzing input)
katana -u $PROD_URL -ef css,png,jpg,svg,woff,woff2 -silent         # drop static noise
katana -u $PROD_URL -H "Cookie: sessionid=..." -silent             # authenticated crawl
```

Then feed the URLs to Nuclei (`nuclei -list all-urls.txt ...`, [lab 57](../57-nuclei-fuzzing))
or ZAP. Unauthenticated crawls miss everything behind login, so for real
coverage pass a session cookie.
