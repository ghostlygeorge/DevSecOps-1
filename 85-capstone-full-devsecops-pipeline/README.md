# Lab 85: Capstone — A Complete DevSecOps Pipeline (exam-style, GitLab CI)

## Goal
Put the course together in one GitLab pipeline for django.nv. Practise
building it from memory. The exam uses GitLab CI, you won't have the lab
instructions, and graders look at your evidence.

```
build ─┬─ build            (DevOps)
       ├─ git-secrets      TruffleHog  ─┐
       └─ sast             Bandit       ├─► DefectDojo (after_script)
test  ─┬─ test             (DevOps)     │
       ├─ oast             Safety       │
       └─ oast-frontend    Retire.js   ─┤
release ── release         docker build/push :$CI_COMMIT_SHA
preprod ── deploy          ssh → prod
integration ─┬─ zap-baseline  ZAP (XML) ┘
             └─ nuclei
prod ─── ansible-hardening (manual) ──► inspec linux-baseline
```

## Prerequisites
- Variables: `PROD_HOSTNAME`, `PROD_USERNAME`, `PROD_SSH_PRIVKEY`, `PROD_URL`,
  `DOJO_HOST`, `DOJO_API_TOKEN`.
- Repo files: `upload-results.py` ([common/](../common/upload-results.py)),
  `ansible-hardening.yml` ([lab 62](../62-ansible-hardening/ansible-hardening.yml)).
- A DefectDojo product + engagement (IDs → `DOJO_PRODUCT` / `DOJO_ENGAGEMENT`).

## Techniques demonstrated
| Technique | Where |
|---|---|
| Docker-based tools with volume mounts | every scan job |
| `allow_failure: true` (maturity 1–2) | every scan job |
| `artifacts: when: always` | every scan job |
| YAML anchors for a reusable upload step | `.dojo_upload` / `after_script: *dojo_upload` |
| Upload in `after_script` (runs after failure) | git-secrets, sast, zap |
| Immutable image tags | `$CI_COMMIT_SHA` |
| Deploy before DAST | `preprod` → `integration` |
| `needs:` for explicit ordering | inspec after hardening |
| Manual gate for risky prod changes | `ansible-hardening: when: manual` |

## Self-test: do it without notes
1. Write the stages and the DevOps build/test jobs.
2. Add one secrets, one SCA, and one SAST job, each producing a JSON artifact without blocking.
3. Add release + deploy (remember `$CI_REGISTRY_PASSWORD`, `tr -d '\r'`, `chmod 600`, `ssh-keyscan`).
4. Add ZAP baseline against prod with an XML report.
5. Upload two reports to DefectDojo from `after_script`.
6. Add InSpec linux-baseline against prod.
7. Then mature it: pick **one** tool and make it a real gate with FP
   handling (Bandit `-b baseline.json -lll -iii` **or** ZAP `-c default.conf`
   with FAIL rules), and remove its `allow_failure`.

## Evidence to keep (the exam is graded manually)
- Screenshot of the pipeline graph (all stages)
- Each job's log tail showing the tool ran and its exit code
- Downloaded artifacts
- DefectDojo engagement page with imported tests
- One paragraph per decision: *why* this stage, *why* non-blocking, *how* FPs are handled
