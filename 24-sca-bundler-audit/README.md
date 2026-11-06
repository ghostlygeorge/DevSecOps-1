# Lab 24: SCA for Ruby with bundler-audit

## Goal
Scan a Rails app's `Gemfile.lock` for vulnerable gems and insecure gem
sources, inside GitLab CI.

## Push the rails project

```bash
source ../lab-env.sh
git clone https://gitlab.practical-devsecops.training/pdso/rails.git rails && cd rails
git remote rename origin old-origin
git remote add origin git@${GITLAB_HOST}:root/rails.git
git push -u origin --all
```

## Run locally first

```bash
docker run --rm -v $(pwd):/src -w /src hysnsec/bundle-audit check; echo $?
docker run --rm -v $(pwd):/src -w /src hysnsec/bundle-audit check --format json --output bundle-audit-output.json
jq '.results[] | {gem: .gem.name, version: .gem.version, id: .advisory.id, criticality: .advisory.criticality}' bundle-audit-output.json
```

`check` reads **`Gemfile.lock`** (exact resolved versions) and compares it
against the ruby-advisory-db. Use `--update` to refresh the DB first.
`--ignore CVE-xxxx` skips advisories, which is how you handle FPs, or put
them in `.bundler-audit.yml`.

## GitLab CI
Paste `ci/gitlab-ci.yml` into `$GITLAB_URL/root/rails/-/blob/main/.gitlab-ci.yml`.
The job fails with exit 1, and `allow_failure: true` keeps the pipeline
going. The JSON report is saved as an artifact.

## Notes
- Pair with **Brakeman** ([lab 37](../37-sast-brakeman)) for Rails SAST.
  bundler-audit checks the gems, Brakeman checks your code.
- Insecure sources (`http://rubygems.org`) are also flagged, since gems
  fetched over HTTP can be swapped by a MITM.
