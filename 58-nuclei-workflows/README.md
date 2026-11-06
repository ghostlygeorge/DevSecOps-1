# Lab 58: Faster DAST in CI with Nuclei Workflows

## Goal
Replace "run all ~6700 templates" (minutes) with a **workflow** tailored to
the app (about a second). That's the difference between DAST that stays in
the pipeline and DAST that gets removed because it's too slow.

## Workflow types

**Generic**: runs every listed template/tag (`generic-workflow.example.yaml`):
```yaml
workflows:
  - template: files/git-config.yaml
  - tags: xss,ssrf,cve,lfi
```

**Conditional**: runs subtemplates only when a parent template's named
matcher fires:
```yaml
workflows:
  - template: technologies/tech-detect.yaml
    matchers:
      - name: vbulletin
        subtemplates:
          - template: exploits/vbulletin-exp1.yaml
      - name: jboss
        subtemplates:
          - template: exploits/jboss-exp1.yaml
```
If no technology is detected, nothing else runs.

## Django workflow

`django-workflow.yaml`: root `http/technologies/tech-detect.yaml`. If it
detects **nginx**, run seven Django-specific checks (admin panel, debug
mode, default page, secret key in settings.py, exposed variables, debug
exposure, framework exceptions).

```bash
# nuclei 2.9.12; templates in ~/nuclei-templates (paths in the workflow are relative to it)
cp ../58-nuclei-workflows/django-workflow.yaml .
nuclei -w django-workflow.yaml -validate        # [INF] All templates validated successfully
nuclei -u $PROD_URL/ -w django-workflow.yaml
# [django-debug] [http] [medium] .../NON_EXISTING_PATH/
# [django-admin-panel] [http] [info] .../admin/login/?next=/admin/
nuclei -u $PROD_URL/ -w django-workflow.yaml -v  # see tech-detect run, then each subtemplate's requests
```

## Benchmark

```bash
time nuclei -u $PROD_URL/ -w django-workflow.yaml          # real 0m0.947s
time nuclei -u $PROD_URL/ -t /root/nuclei-templates/        # real 2m22.664s
```

Look at `real`, the wall-clock time from Enter to exit.

The workflow finds the same two Django issues roughly 150× faster. The
full scan adds generic header/TLS/DNS info findings, which you can cover with
a separate scheduled (nightly) full scan.

## In CI
```yaml
nuclei-django:
  stage: integration
  script:
    - docker run --rm -v $(pwd):/nuclei -w /nuclei projectdiscovery/nuclei:v2.9.12 -u $PROD_URL -w django-workflow.yaml -j -o nuclei-output.json
  artifacts: { paths: [nuclei-output.json], when: always }
  allow_failure: true
```
(Commit `django-workflow.yaml` to the repo.)

## Notes
- Matching on `nginx` is a proxy for "our known stack". On a different
  server stack the subtemplates silently never run. Choose the parent
  matcher carefully, or use a generic workflow for things that must
  always run.
- Template paths change between nuclei-templates releases (e.g. the
  `http/` prefix was added in v9.4). Run `-validate` after updating
  templates.
