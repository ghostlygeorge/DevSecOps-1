# Lab 07: Docker CLI Basics

## Goal
Almost every security tool in this course runs as `docker run --rm -v
$(pwd):/src <image> ...`. Get fluent with the commands behind that.

## pull

```bash
docker pull ubuntu            # no tag -> :latest (assumed!)
docker pull -q alpine         # -q/--quiet: only print the image reference
docker images
```

Pin tags in pipelines (`hysnsec/bandit:<ver>`, `zap-stable:2.13.0`).
`:latest` means your scan results change under you between runs.

## run

```bash
docker run -d --name myubuntu ubuntu      # -d detached; exits immediately (no foreground process)
docker ps                                 # not listed
docker ps -a                              # Exited (0)
docker run -d --name myubuntu -i ubuntu   # Conflict: name already in use
docker rm myubuntu
docker run -d --name myubuntu -i ubuntu   # -i keeps STDIN open -> bash waits -> stays up
docker ps
docker run busybox                        # run auto-pulls missing images
```

## exec / ps / top

```bash
docker exec myubuntu whoami                 # root
docker exec myubuntu cat /etc/lsb-release
docker exec -it myubuntu bash               # -i stdin + -t pseudo-TTY = interactive shell
exit
docker run -d --name yourubuntu ubuntu
docker ps -a                                # -a includes exited containers
docker top myubuntu                         # processes inside the container
```

**Without `-a`** you only see running containers. Exited ones (the usual
state for a scanner container) are hidden.

## build (preview of lab 11)

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv && cd django.nv
cat Dockerfile
docker build -t django.nv:1.0 .
```

| Instruction | Meaning |
|---|---|
| FROM | base image |
| WORKDIR | `cd` for later instructions (and the default for the container) |
| COPY | host → image |
| RUN | execute at **build** time, creates a layer |
| EXPOSE | documents the port (doesn't publish it) |
| CMD | default command at **run** time |

## The scanner pattern decoded

```bash
docker run --rm --user $(id -u):$(id -g) -v $(pwd):/src -w /src hysnsec/bandit -r /src -f json -o /src/bandit-output.json
```

| Part | Why |
|---|---|
| `--rm` | delete the container when it exits (no `docker ps -a` clutter) |
| `--user $(id -u):$(id -g)` | files written to the mount are owned by **you**, not root |
| `-v $(pwd):/src` | the code goes in **and** the report comes out |
| `-w /src` | relative paths inside the tool resolve against the mount |
| `-o /src/...` | write **inside the mount**, otherwise the report vanishes with the container |

## Cleanup

```bash
docker rm -f myubuntu yourubuntu
docker system prune -f        # remove stopped containers, dangling images, unused networks
```
