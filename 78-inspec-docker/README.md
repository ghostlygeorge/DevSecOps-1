# Lab 78: Docker Compliance with InSpec — CIS Docker Benchmark and Container Baselines

## Goal
Audit the **Docker host/daemon** against the CIS Docker Benchmark, and a
**running container** against the Linux baseline. Watch how runtime
checks kick in once containers exist.

## Docker daemon / host

```bash
bash ../71-inspec-basics/install-inspec.sh
mkdir inspec && cd inspec        # (course: run from an empty dir so the git URL fetch works cleanly)
inspec exec https://github.com/dev-sec/cis-docker-benchmark.git --chef-license accept
# × docker-4.2: Use trusted base images for containers  -> DOCKER_CONTENT_TRUST expected "1" got nil
# ↺ docker-4.3 ... (manual checks are skipped)
# × host-1.7: Audit docker daemon -> auditd missing, /sbin/auditctl does not exist
# Profile Summary: 21 successful controls, 36 control failures, 18 controls skipped
```

Typical failures and fixes:

| Control | Fix |
|---|---|
| docker-4.2 / 4.5 content trust | `export DOCKER_CONTENT_TRUST=1` (signed images only) |
| host-1.7–1.15 audit Docker files | install `auditd` + rules for `/usr/bin/dockerd`, `/var/lib/docker`, `/etc/docker`, `docker.service`/`.socket` |
| docker-2.x daemon | `/etc/docker/daemon.json`: `icc: false`, `userns-remap`, `live-restore`, `no-new-privileges`, log driver |

## Running containers

```bash
docker run -d --name alpine -it alpine /bin/sh
docker ps
inspec exec https://github.com/dev-sec/linux-baseline.git --chef-license accept -t docker://alpine     # name or id
# × os-02: /etc/shadow should not be readable by group ...
# Profile Summary: 16 successful controls, 3 control failures, 38 controls skipped
```

`-t docker://<container>` runs checks **inside** the container via the
Docker API. Nothing is installed in the container.

## Re-run the CIS benchmark now that a container exists

```bash
inspec exec https://github.com/dev-sec/cis-docker-benchmark.git --chef-license accept
# Profile Summary: 35 successful controls, 47 control failures, 18 controls skipped
```

It went from 21/36 to 35/47 because the **container runtime** controls
(`controls/container_runtime.rb`: privileged mode, capabilities, mounts,
PID/network namespace sharing, memory/CPU limits, read-only rootfs,
healthchecks, ...) only evaluate when containers are running. With none,
they had nothing to check.

## Use it as a gate
Scan a freshly built image's container in CI **before** pushing:
```bash
docker run -d --name candidate $IMAGE sleep 600
inspec exec linux-baseline -t docker://candidate --reporter cli json:container.json
docker rm -f candidate
```
