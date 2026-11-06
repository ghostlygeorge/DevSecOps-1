#!/usr/bin/env python3
"""
Extra-mile challenge (course provides no solution): wrap Bandit's JSON
output, pretty-print it with colours, and fail the build only when the
finding counts reach a threshold, e.g. 3 high, 1 medium, 1 low.

  bandit -r . -f json -o bandit-output.json --exit-zero
  python3 bandit_gate.py bandit-output.json --high 3 --medium 1 --low 1

Exit 1 when ANY threshold is reached, else 0.
Containerise it with the Dockerfile.gate next to this file.
"""
import argparse
import json
import sys

COLOURS = {"HIGH": "\033[31m", "MEDIUM": "\033[34m", "LOW": "\033[33m"}  # red / blue / orange-ish
RESET = "\033[0m"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("report")
    p.add_argument("--high", type=int, default=1)
    p.add_argument("--medium", type=int, default=10**9)
    p.add_argument("--low", type=int, default=10**9)
    a = p.parse_args()

    with open(a.report) as fh:
        results = json.load(fh).get("results", [])

    counts = {"HIGH": 0, "MEDIUM": 0, "LOW": 0}
    for r in sorted(results, key=lambda r: ["HIGH", "MEDIUM", "LOW"].index(r["issue_severity"])):
        sev = r["issue_severity"]
        counts[sev] = counts.get(sev, 0) + 1
        print("%s[%s/%s] %s %s:%s%s  %s" % (COLOURS.get(sev, ""), sev, r["issue_confidence"],
              r["test_id"], r["filename"], r["line_number"], RESET, r["issue_text"]))

    print("\nHIGH=%(HIGH)d MEDIUM=%(MEDIUM)d LOW=%(LOW)d" % counts)
    limits = {"HIGH": a.high, "MEDIUM": a.medium, "LOW": a.low}
    breached = [s for s in limits if counts[s] >= limits[s]]
    if breached:
        print("FAIL: thresholds reached for " + ", ".join(breached))
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
