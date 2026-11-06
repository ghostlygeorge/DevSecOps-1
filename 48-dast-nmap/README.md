# Lab 48: Network Scanning with Nmap

## Goal
Discover open ports and services on the production host with **Nmap** and
save XML for automation, so you notice unexpected exposed services.

## Install / scan

```bash
apt-get update && apt-get install nmap -y
nmap -help
nmap $PROD_HOST -oX nmap_out.xml
# PORT     STATE SERVICE
# 22/tcp   open  ssh
# 80/tcp   open  http
# 8000/tcp open  http-alt     <- the Django dev server exposed directly, bypassing nginx!
cat nmap_out.xml
```

| Option | Meaning |
|---|---|
| `-oX/-oN/-oG/-oA base` | XML / normal / grepable / all three |
| `-sS` / `-sT` / `-sU` | SYN (root) / connect / UDP scan |
| `-p 1-65535`, `-p-`, `--top-ports N`, `-F` | port selection |
| `-sV` | service/version detection |
| `-sC` / `--script=vuln` | NSE default / vuln scripts |
| `-O` | OS detection |
| `-Pn` | skip host discovery (hosts that drop ping) |
| `-T0..5` | timing (T4 typical in labs) |

## Make it useful in CI
Compare against an **expected-ports allowlist** and fail on drift:

```bash
nmap -p- -T4 $PROD_HOST -oG - | grep -oE '[0-9]+/open' | cut -d/ -f1 | sort -n > open.txt
diff <(printf "22\n80\n443\n") open.txt && echo "no unexpected ports" || { echo "PORT DRIFT"; exit 1; }
```

Port 8000 being reachable here is a real finding: the app server should
only listen on localhost behind nginx (`-p 127.0.0.1:8000:8000`).

## Notes
- DefectDojo: `Nmap Scan` (XML).
- Only scan hosts you're authorised to test.
- Default scans cover the top 1000 TCP ports only (`Not shown: 997 closed ports`).
