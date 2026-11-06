# Lab 00: Exam Strategy and Lab Environment

## Goal
Understand how the Practical DevSecOps (CDP) lab portal and exam work, and
set up this repo so every later lab's commands work against **your** lab
machines.

## Exam facts that change how you study

| Fact | Consequence |
|---|---|
| Hands-on, **open-book** | You may use notes, but **not the lab instructions**. This repo is meant to *be* your notes. |
| **GitLab CI** is the exam CI system | Jenkins/GitHub Actions variants are good practice, but master the GitLab versions first. |
| Graded **manually** from your documentation/evidence (3+ evaluators, 6 evaluations) | Screenshot pipelines, keep job logs, keep artifacts, write down *why* you did each thing. |
| **No** automated answer checking during the exam | You won't be told when an answer is right. Validate yourself: check exit codes, artifacts, and pipeline status. |

### Study order (from the course)
1. Do the **Mandatory** exercises first.
2. Do them a second time.
3. Write notes of every command and flag (this repo plus `CHEATSHEET.md`).
4. Try every **Challenge** before reading its answer.
5. Take the practice exam if one is offered.

### "Check your Task" button
If the auto-checker rejects a correct alternative answer, run the commands
from the **Answer** section. The checker only recognises some valid
solutions.

Resources: <https://www.practical-devsecops.com/exam-and-certification/>,
<https://www.practical-devsecops.com/faq/>, and the course's *exam-and-certification-process* video lecture.

## Lab machines

| Machine | Short hostname | Purpose | Lifetime |
|---|---|---|---|
| DevSecOps-Box | `devsecops-box-<id>` | Your workstation / jump box, full of tools | Until the lab timer ends |
| GitLab (SCM + CI) | `gitlab-ce-<id>` | Repos, pipelines, registry | **2 hours** |
| GitLab runner | – | Executes CI jobs (no SSH) | 2 hours |
| Production | `prod-<id>` | Deploy / DAST / hardening target | 2 hours |
| DefectDojo | `dojo-<id>` | Vulnerability management | 2 hours |
| Others on demand | `jenkins-`, `sonarqube-`, `sandbox-`, `registry-`, `gitlab-registry-` | Per exercise | 2 hours |

`<id>` is your machine ID (e.g. `jbekkra7`). Public URLs follow
`https://<host>-<id>.lab.practical-devsecops.training`.

> After 2 hours every machine **except** the DevSecOps-Box shuts down, even
> mid-exercise. On a 404, refresh the exercise page and click **Start the
> Exercise** again. Always click **Start the Exercise**, or nothing gets
> provisioned. Wait ~2 minutes for GitLab/Dojo/Prod to boot.

Default credentials: GitLab/Jenkins/Dojo/Sonar `root|admin` / `pdso-training`.
Task Manager app (django.nv) on prod: `admin` / `admin`.

## Using this repo

```bash
export LAB_ID=$(hostname | sed 's/^devsecops-box-//')   # or set it by hand
source /path/to/DevSecOps/lab-env.sh

echo $PROD_HOST $GITLAB_URL $DOJO_URL
ping -c 3 $PROD_HOST
ping -c 3 $DOJO_HOST_SHORT
```

Every pipeline/config file in this repo uses the literal token `LABID` in
hostnames. Before pasting into GitLab:

```bash
labcat 34-sast-bandit/ci/gitlab-ci.yml          # print with LABID replaced
labify my-copy/.gitlab-ci.yml                    # rewrite in place
```

## Pasting into the browser terminal
- Ctrl+V / Cmd+V, or **Ctrl+Shift+Insert** on Windows, or right-click → Paste.
- A copied command block shows a tick mark when it's on your clipboard.

## Support
`cdp` channel on the course Mattermost.

## Lab map
See the [root README](../README.md). Cross-tool syntax lives in
[CHEATSHEET.md](../CHEATSHEET.md), and exit codes are in [lab 06](../06-exit-codes).
