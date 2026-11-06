# Lab 46: DAST with Nikto

## Goal
Scan the production web server with **Nikto** for default files, insecure
configs, outdated software, and missing headers. Learn its config file and
plugin options.

Nikto is Perl, built on LibWhisker2. It supports SSL, proxies, host auth,
and IDS-evasion encodings.

## Install

```bash
apt install -y libnet-ssleay-perl            # SSL support
git clone https://github.com/sullo/nikto
cd nikto/program
git checkout tags/2.1.6
./nikto.pl -Help
```

| Option | Use |
|---|---|
| `-h/-host`, `-url` | target |
| `-p/-port`, `-ssl`, `-nossl` | port / force SSL |
| `-o/-output FILE`, `-Format csv\|json\|htm\|xml\|txt\|nbe\|sql` | output (format guessed from extension) |
| `-Tuning 1..9,a-e,x` | test categories: 2 misconfig, 3 info disclosure, 4 XSS, 9 SQLi, x reverse ... |
| `-Plugins LIST`, `-list-plugins` | choose plugins |
| `-maxtime 1h`, `-Pause`, `-timeout` | keep CI runs bounded |
| `-config FILE` | alternate nikto.conf |
| `-evasion 1..8,A,B` | IDS evasion encodings |

## Scan

```bash
source /path/to/lab-env.sh
./nikto.pl -output nikto_output.xml -h $PROD_HOST
#  + Server: nginx/1.14.0 (Ubuntu)
#  + The X-Content-Type-Options header is not set...
#  + nginx/1.14.0 appears to be outdated (current is at least 1.18.0)
#  + OSVDB-17113: /SilverStream: SilverStream allows directory listing
cat nikto_output.xml
```

Save machine-readable output (XML/JSON/CSV) so it can be parsed and uploaded
(DefectDojo: `Nikto Scan`).

## nikto.conf parameters

| Parameter | Purpose |
|---|---|
| `SKIPIDS` | test IDs to skip (known false positives) |
| `SKIPPORTS` | ports never scanned, even if open |
| `CLIOPTS` | default CLI options (output, format, ...) |
| `STATIC-COOKIE` | fixed `Cookie:` header, for authenticated scans |
| `TIMEOUT` | per-request timeout |
| `EXTRAREQS` | 0/1, use non-standard HTTP methods to reveal more (slower, noisier) |

## Challenges

```bash
./nikto.pl -list-plugins                                    # 1: list plugins
./nikto.pl -h $PROD_HOST -Plugins headers                   # 2: headers plugin only
cp nikto.conf nikto.conf.orig                               # 3: skip 21/22/111, CSV output
cp ../../46-dast-nikto/nikto.conf.challenge /nikto/program/nikto.conf
./nikto.pl -h $PROD_HOST -config nikto.conf
ls result.csv
```

> Overwriting `nikto.conf` with only two lines drops the shipped defaults
> (DB paths, user agent, ...). The course does exactly this and it works
> for 2.1.6, but appending (`>>`) is safer.

## Notes
- Nikto is **loud**, with ~7–8k requests per run. It's easily detected and
  not stealthy. Only scan targets you're authorised to test.
- `-h prod-<id>` defaults to port 80. Add `-ssl -p 443` or use the https URL.
