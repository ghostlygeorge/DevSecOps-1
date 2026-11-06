# Lab 11: Writing Dockerfiles — From Broken to Working

## Goal
Build an nginx image by fixing a Dockerfile one error at a time, and
understand `RUN` vs `CMD` vs `ENTRYPOINT`. These are the instructions
hadolint (lab 43) lints.

| Instruction | When it runs | Notes |
|---|---|---|
| FROM | build | base image layer |
| COPY | build | local files → image |
| ADD | build | like COPY + URL download + auto-extract tarballs. Prefer COPY (hadolint DL3020) |
| RUN | **build** | each RUN = a layer |
| CMD | **run** | default command, or default **args** to ENTRYPOINT. Only the **last** CMD counts. |
| ENTRYPOINT | **run** | the fixed executable. `docker run img X` replaces CMD, not ENTRYPOINT |

## Files
- `steps/Dockerfile.1..8`: the course's progression, each annotated with why it fails or works.
- `Dockerfile.best-practice`: the version you'd actually ship.
- `run-steps.sh`: builds and runs every step and prints the outcome.

## Walkthrough

```bash
mkdir learn-dockerfile && cd learn-dockerfile
cp ../steps/Dockerfile.1-no-update Dockerfile && docker build -t nginx-custom .   # E: Unable to locate package nginx
cp ../steps/Dockerfile.2-interactive Dockerfile && docker build -t nginx-custom . # [Y/n] Abort.
cp ../steps/Dockerfile.3-builds Dockerfile && docker build -t nginx-custom .      # Successfully tagged
docker images
```

### Prototype interactively first, then codify

```bash
docker run -d --name ubuntu -it ubuntu:20.04
docker exec -it ubuntu bash
apt update && apt install -y nginx       # answer the tzdata region prompt
service nginx start
curl localhost                           # bash: curl: command not found
apt install curl -y && curl localhost    # Welcome to nginx!
exit
```

### Why the container exits

```bash
cp ../steps/Dockerfile.4-exits Dockerfile
docker build -t custom-nginx . && docker run -d -it --name custom-nginx-container custom-nginx
docker ps -a                              # Exited (0)
docker logs custom-nginx-container        # * Starting nginx nginx [OK]
```

A container lives exactly as long as **PID 1**. `service nginx start`
forks nginx into the background and returns, so bash exits and the
container stops. (StackOverflow: "Dockerfile CMD instruction will exit the container just after running it".)

Fixes in order of quality: `sleep infinity` (step 6, crude), ENTRYPOINT +
CMD (step 7), or run nginx in the foreground (`nginx -g 'daemon off;'`,
best-practice file).

```bash
cp ../steps/Dockerfile.8-entrypoint-exits Dockerfile
docker build -t custom-nginx . && docker rm -f custom-nginx-container
docker run -d -it --name custom-nginx-container custom-nginx ; docker ps    # not running
docker run -d --name nginx-one -it custom-nginx bash ; docker ps            # running. Why?
```

**Why is `nginx-one` alive?** `bash` replaced CMD, so the container runs
`/bin/bash -c bash`. That's an interactive bash with `-i` keeping stdin
open, and it never exits. nginx isn't actually started in it.

## Notes
- Exec form `["a","b"]` vs shell form `a b`: the exec form doesn't wrap in
  `/bin/sh -c`, so the process is PID 1 and receives SIGTERM on
  `docker stop`.
- Missing from the course Dockerfiles: a non-root `USER`, pinned base digest,
  `HEALTHCHECK`. hadolint/Checkov/Trivy flag these (labs 43, 66, 28).
