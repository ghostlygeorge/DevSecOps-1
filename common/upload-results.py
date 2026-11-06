#!/usr/bin/env python3
"""
CI/CD integration for DefectDojo — upload a scanner report to an engagement.

RECONSTRUCTION: the course fetches this script from
  https://gitlab.practical-devsecops.training/-/snippets/3/raw
(curl ... -o upload-results.py). That snippet's source was never shown, so
this is a functionally equivalent rewrite that exposes the exact same CLI
used in every DefectDojo exercise. If you have lab access, prefer the
original snippet.

Example:
  python3 upload-results.py --host $DOJO_HOST --api_key $API_KEY \
      --engagement_id 1 --product_id 1 --lead_id 1 --environment "Production" \
      --result_file bandit-output.json --scanner "Bandit Scan"

--scanner must be an exact DefectDojo parser name (case sensitive), e.g.
"Bandit Scan", "ZAP Scan", "Brakeman Scan", "Gitleaks Scan",
"Trufflehog3 Scan", "Dependency Check Scan", "Retire.js Scan", "Semgrep JSON Report",
"Checkov Scan", "Nuclei Scan", "SSLyze Scan (JSON)", "Nmap Scan", "Nikto Scan".
Full list: https://docs.defectdojo.com/en/connecting_your_tools/parsers/
"""
import argparse
import datetime
import sys

import requests


def upload_results(host, api_key, scanner, result_file, engagement_id,
                   lead_id, environment, build_id=None, verify=True):
    if not host.startswith("http"):
        host = "https://" + host
    url = host.rstrip("/") + "/api/v2/import-scan/"
    headers = {"Authorization": "Token " + api_key}

    data = {
        "scan_type": scanner,
        "engagement": engagement_id,
        "lead": lead_id,
        "environment": environment,
        "scan_date": datetime.date.today().isoformat(),
        "minimum_severity": "Info",
        "active": "true",
        "verified": "false",
        "close_old_findings": "false",
    }
    if build_id:
        data["build_id"] = build_id

    with open(result_file, "rb") as fh:
        r = requests.post(url, headers=headers, data=data,
                          files={"file": fh}, verify=verify, timeout=300)
    return r


def main():
    p = argparse.ArgumentParser(description="CI/CD integration for DefectDojo")
    p.add_argument("--host", required=True, help="DefectDojo Hostname")
    p.add_argument("--api_key", required=True, help="API v2 Key")
    p.add_argument("--engagement_id", required=True, help="Engagement ID")
    p.add_argument("--result_file", required=True, help="Scanner file")
    p.add_argument("--scanner", required=True, help="Type of scanner")
    p.add_argument("--product_id", required=True, help="DefectDojo Product ID")
    p.add_argument("--lead_id", required=True, help="ID of the user conducting the testing")
    p.add_argument("--environment", required=False, default="Production", help="Environment name")
    p.add_argument("--build_id", required=False, help="Reference to external build id")
    p.add_argument("--insecure", action="store_true", help="Skip TLS verification")
    a = p.parse_args()

    r = upload_results(a.host, a.api_key, a.scanner, a.result_file,
                       a.engagement_id, a.lead_id, a.environment,
                       a.build_id, verify=not a.insecure)
    if r.status_code in (200, 201):
        print("Successfully uploaded the results to DefectDojo")
        return 0
    # 500 here almost always means: unknown --environment name, wrong
    # --scanner string, or a report format the parser doesn't accept.
    print("Something went wrong, please debug " + str(r.text), file=sys.stderr)
    print("HTTP status: %s" % r.status_code, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
