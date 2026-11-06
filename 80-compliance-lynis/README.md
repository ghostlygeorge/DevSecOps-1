# Lab 80: Security Compliance Auditing with Lynis

## Goal
Run **Lynis**, an agentless security auditing tool for Unix-like systems,
on the DevSecOps-Box, read its hardening index, and know where its data
goes for automation.

## Install

```bash
apt-get install lynis           # Lynis 2.6.2 from Ubuntu repos (latest upstream is 3.x)
lynis show help                 # commands: audit, configure, show, update, upload-only
lynis audit system --help
```

| Command | Use |
|---|---|
| `lynis audit system` | audit the local host |
| `lynis audit system remote <host>` | prints the steps to audit a remote host (copy tarball + run) |
| `lynis audit dockerfile <file>` | analyse a Dockerfile |
| `--quick/-Q` | no pauses (CI) |
| `--pentest` | non-privileged scan |
| `--profile <file>` | custom profile (skip tests, set values) |
| `--no-colors`, `--quiet` | CI output |

## Audit

```bash
lynis audit system
```

Summary block:

| Item | Meaning |
|---|---|
| **Hardening index: 59** `[###########   ]` | score /100 from all checks. Moderate. Track it over time. |
| **Tests performed: 216** | basic to deep checks |
| **Plugins enabled: 1** | extra checks/integrations |
| Firewall `[V]` | configured and active |
| Malware scanner `[X]` | none installed/running |
| Compliance Status `[?]` | not determinable without a compliance profile (enterprise) |
| Security Audit `[V]` / Vulnerability Scan `[V]` | modules ran successfully |
| `/var/log/lynis.log` | detailed test/debug log |
| `/var/log/lynis-report.dat` | **machine-readable** key=value report. Parse it in automation. |

```bash
grep -E '^(warning|suggestion)\[\]' /var/log/lynis-report.dat | head
grep '^hardening_index=' /var/log/lynis-report.dat
lynis show details SSH-7408         # explain one test id
```

Each warning or suggestion has a test ID (e.g. `SSH-7408`, `KRNL-6000`)
with a link to the CISOfy control page.

## In CI / at scale
```bash
lynis audit system --quick --no-colors > lynis.txt
awk -F= '/^hardening_index=/{ if ($2 < 70) { print "Hardening index " $2 " < 70"; exit 1 } }' /var/log/lynis-report.dat
```
Run it with Ansible across the fleet and collect `lynis-report.dat` from
each host.

## Lynis vs InSpec
| | Lynis | InSpec |
|---|---|---|
| Content | built-in ~250 tests | you write or import profiles (CIS, dev-sec, ASVS...) |
| Output | hardening index + suggestions | pass/fail per control, many reporters |
| Customisation | profiles to skip/tune | full code |
| Best for | quick broad health check | precise, auditable policy as code |

`[TIP]: Enhance Lynis audits by adding your settings to custom.prf`. Copy
settings from `/etc/lynis/default.prf`.
