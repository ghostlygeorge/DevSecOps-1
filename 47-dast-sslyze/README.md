# Lab 47: TLS Configuration Scanning with SSLyze

## Goal
Audit the production server's TLS setup (protocols, cipher suites,
certificate chain, Heartbleed/ROBOT/CCS) with **SSLyze**, and check it
against Mozilla's recommended configuration.

## Install

```bash
pip3 install sslyze==5.0.3
sslyze --help
```

Key options: `--json_out FILE` (`-` for stdout), `--targets_in FILE`,
`--mozilla_config modern|intermediate|old|disable` (default intermediate),
`--certinfo`, `--tlsv1_2`, `--heartbleed`, `--robot`, `--http_headers`,
`--starttls smtp|...`, `--slow_connection`, `--quiet`.

## Scan

```bash
sslyze --json_out sslyze-output.json prod-${LAB_ID}.lab.practical-devsecops.training:443
```

How to read the result:

| Section | Result on prod |
|---|---|
| Certificate | `*.lab.practical-devsecops.training`, Let's Encrypt R3, 2048-bit RSA, trusted by Android/Apple/Java/Mozilla/Windows stores |
| Extensions | OCSP Must-Staple not supported. Certificate Transparency: only 2 SCTs (Google recommends 3). |
| SSL 2.0 / 3.0 / TLS 1.0 / 1.1 | all rejected (good) |
| TLS 1.2 | 5 ECDHE suites. Forward secrecy OK, no RC4. |
| TLS 1.3 | 3 suites |
| Compression / CCS / Heartbleed / ROBOT / Renegotiation | not vulnerable |
| **Mozilla intermediate** | **FAILED**: `TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256` and `..._AES_256_CBC_SHA384` are supported but should be rejected (CBC suites) |

```bash
jq '.server_scan_results[0].scan_result.ssl_3_0_cipher_suites.result.accepted_cipher_suites | length' sslyze-output.json
jq '.server_scan_results[0].scan_result.tls_1_2_cipher_suites.result.accepted_cipher_suites[].cipher_suite.name' sslyze-output.json
```

**Fix** (nginx): restrict `ssl_ciphers` to Mozilla's intermediate list (ECDHE + AES-GCM/CHACHA20 only).
Generator: <https://ssl-config.mozilla.org/>.

## CI note
The Mozilla-compliance check makes sslyze exit **non-zero when not
compliant** (since 5.0), so it can gate. Use `--mozilla_config disable`
to report only. Docker: `hysnsec/sslyze`
([lab 49](../49-dast-pipeline-nikto-sslyze-nmap)). DefectDojo: `SSLyze Scan (JSON)`.
