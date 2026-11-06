# Lab 37: SAST for Rails with Brakeman

## Goal
Scan a Ruby on Rails app with Brakeman and ignore findings by
**fingerprint** with `brakeman.ignore`.

## Setup

```bash
git clone https://gitlab.practical-devsecops.training/pdso/rails.git webapp && cd webapp
apt update && apt install ruby-full -y
gem install brakeman -v 5.2.1
brakeman -h
```

Notable flags: `-f json` format, `-o FILE` output, `-i FILE` ignore config,
`-I` interactive ignore, `-w 1..3` minimum confidence, `-z/--exit-on-warn`
(default), `--compare OLD.json` (diff two scans), `-A` run all checks
including optional ones, `-t/-x` include/exclude checks.

## Scan

```bash
brakeman -f json | tee result.json          # ~6 Medium + ~11 High confidence warnings
jq '.warnings[] | {warning_type, confidence, file, line, fingerprint}' result.json | head -40
```

## Ignore a warning by fingerprint

```bash
cp ../37-sast-brakeman/brakeman.ignore .
brakeman -f json -i brakeman.ignore | tee result.json     # the XSS warning is gone
jq '.ignored_warnings | length' result.json
```

The fingerprint is a hash of the warning's type, location, and code, so it
stays valid when line numbers shift. Easier: `brakeman -I` walks you through
each warning and writes `config/brakeman.ignore` (with `--ensure-ignore-notes`
to force a note on every ignore).

## CI
Docker: `docker run --rm -v $(pwd):/src hysnsec/brakeman -f json /src`
(used again in the DefectDojo lab). See `gitlab-ci-brakeman.yml`.
Exit code **3** when warnings exist.

## Notes
- Brakeman needs a Rails app layout (`app/`, `config/`). Use `--force-scan` otherwise.
- Pair with bundler-audit ([lab 24](../24-sca-bundler-audit)) for gem CVEs.
- DefectDojo scanner name: `Brakeman Scan`.
