# Lab 57: Fuzzing with Katana + Nuclei Fuzzing Templates

## Goal
Pipeline two tools: **Katana** finds URLs that have query parameters, then
**Nuclei fuzzing templates** inject XSS/SQLi/SSRF/SSTI/LFI/RFI/open-redirect
payloads into each parameter.

Target: Google's **Public Firing Range** (`https://public-firing-range.appspot.com/`),
a deliberately vulnerable test bed.

## Install

```bash
wget https://github.com/projectdiscovery/nuclei/releases/download/v2.9.12/nuclei_2.9.12_linux_amd64.zip
unzip nuclei_2.9.12_linux_amd64.zip && mv nuclei /usr/bin/
wget https://github.com/projectdiscovery/katana/releases/download/v1.0.3/katana_1.0.3_linux_amd64.zip
unzip katana_1.0.3_linux_amd64.zip && mv katana /usr/bin/
```

## 1. Enumerate fuzzable endpoints

`-f qurl` = "URL including query params", e.g.
`https://admin.projectdiscovery.io/admin/login.php?user=admin&password=admin`.

```bash
katana -u https://public-firing-range.appspot.com/ -f qurl -o endpoints.txt
sed -i '/^$/d' endpoints.txt          # drop empty lines
wc -l endpoints.txt                   # ~144
```

## 2. Fuzz

```bash
git clone https://github.com/projectdiscovery/fuzzing-templates.git
nuclei -list endpoints.txt -t fuzzing-templates
# [open-redirect] [http] [medium] .../urldom/redirect?url=https://evil.com
# [reflected-xss] [http] [medium] .../escape/js/escape?q=a'"><57354
# [reflected-xss] [http] [medium] .../reflected/parameter/body?q=a'"><57354   ... ~40 results

nuclei -list endpoints.txt -t fuzzing-templates -verbose
# [VER] [linux-lfi-fuzz] Sent HTTP request to ...?q=/etc/passwd
# [VER] [CVE-2018-19518] Sent HTTP request to ...?q=x+-oProxyCommand=echo+...|base64+-d|sh}
# [VER] [reflection-ssti] Sent HTTP request to ...?q=test${3266*7997}
# [VER] [fuzz-xxe] / [cookie-injection] / [rfi] / [open-redirect] ...
```

`-verbose` shows each payload. The `[WRN] Headless flag is required for
headless template` messages concern the DOM-XSS / CSTI templates, which only
run with `-headless`.

## How the fuzz templates work
```yaml
http:
  - pre-condition: [...]
    payloads: { reflection: ["'\"><{{randstr}}"] }
    fuzzing:
      - part: query           # mutate each query parameter
        type: postfix         # replace | prefix | postfix | infix
        mode: single          # one param at a time (or multiple)
        fuzz: ["{{reflection}}"]
    matchers: [ { type: word, part: body, words: ["{{reflection}}"] } ]   # payload reflected unencoded -> XSS
```
Override from the CLI: `-fuzzing-type`, `-fuzzing-mode`.

## Notes
- Fuzzing sends **attack payloads**. Only point it at targets you own or
  that explicitly allow it (Firing Range does).
- Nuclei 3.x merged fuzzing templates into the main repo under `dast/`,
  enabled with `-dast`.
- Interactsh (`oast.pro`, ...) receives out-of-band callbacks for blind
  SSRF/RCE. `-ni` disables it if egress is restricted.
