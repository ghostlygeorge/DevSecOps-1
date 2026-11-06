# Lab 23: SCA with AuditJS (Sonatype OSS Index)

## Goal
Audit npm dependencies against Sonatype's OSS Index with AuditJS, and
embed it into a Node.js project's GitLab pipeline.

## Setup and scan

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv webapp && cd webapp
bash ../20-sca-retirejs/install-node.sh
npm install -g auditjs
auditjs -h            # iq (Nexus IQ server) | config | ossi (OSS Index)
auditjs ossi --help

auditjs ossi          # ERROR: Failed project directory validation ... Could not instantiate muncher
npm install           # auditjs needs a BUILT node project (node_modules)
auditjs ossi          # table: [335/350] pkg:npm/utile@0.2.1 - 1 vulnerability found! CVSS 9.1 ...
auditjs ossi -q -j | tee auditjs-output.json   # -q only vulnerable deps, -j JSON
jq '.[] | {coordinates, n: (.vulnerabilities|length)}' auditjs-output.json
```

| Flag | Meaning |
|---|---|
| `-q` | quiet, only print vulnerable dependencies |
| `-j` / `-x` | JSON / JUnit XML |
| `-w FILE` | whitelist (ignore) file, the FP mechanism |
| `-u` / `-p` | OSS Index username/token. Anonymous use is rate limited, and Sonatype now **requires** a free account for OSS Index. |

How to figure out commands like `npm install` first: read the project docs,
or try it, read the error, and iterate.

## GitLab CI (nodejs project)

```bash
git clone https://gitlab.practical-devsecops.training/pdso/nodejs.git nodejs && cd nodejs
git remote rename origin old-origin
git remote add origin git@${GITLAB_HOST}:root/nodejs.git
git push -u origin --all
cp ../23-sca-auditjs/ci/gitlab-ci.yml .gitlab-ci.yml && git add . && git commit -m auditjs && git push
```

The pipeline uses `node:alpine3.10` as the default image with a
`node_modules/` cache. The `auditjs` job overrides to `docker:dind` because
it runs the tool as a container.

> **Course erratum:** the final "allow failure" version drops `image:
> docker:dind` from the auditjs job. The job then runs on `node:alpine3.10`,
> which has no `docker` binary, so it fails with `docker: not found`
> instead of reporting findings. Keep the image override (as in `ci/`).
> There's also no `services: docker:dind`. That works only if the runner
> mounts the docker socket, so add it if you get `Cannot connect to the
> Docker daemon`.
