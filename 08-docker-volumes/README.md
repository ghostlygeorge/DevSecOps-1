# Lab 08: Managing Data in Docker — Volumes vs Bind Mounts

## Goal
Understand where a container's files live, so you can (a) get scanner
reports out and (b) understand why mounting host paths is a security
decision.

## Named volumes (Docker-managed)

```bash
docker volume --help
docker volume ls
docker volume create demo
ls /var/lib/docker/volumes/                 # demo  metadata.db

docker run --name ubuntu -d -v demo:/opt -it ubuntu:20.04
docker exec -it ubuntu bash
echo "Welcome to the containers" > /opt/welcome.txt
exit
docker rm -f ubuntu
ls /var/lib/docker/volumes/demo/_data/      # welcome.txt survives the container

docker run --name ubuntu1 -d -v demo:/tmp -it ubuntu:20.04
docker exec -it ubuntu1 ls /tmp             # welcome.txt, same volume at a different path
```

Files written **outside** the mounted path die with the container.

## Bind mounts (host path → container path)

```bash
docker run --name ubuntu2 -d -v /opt:/opt -it ubuntu:20.04
docker exec -it ubuntu2 ls /opt             # containerd: the HOST's /opt
ls /var/lib/docker/volumes                  # nothing new, bind mounts aren't volumes

echo "Hello from the host" > /opt/welcome.txt
docker rm -f ubuntu2
docker run --name ubuntu2 -d -v /opt:/opt -it ubuntu:20.04
docker exec -it ubuntu2 bash -c 'ls /opt; rm /opt/welcome.txt'
ls /opt/welcome.txt                         # gone on the host too
```

The host and container share the same files: a delete in either place is a delete in both.

**Why `-v` is needed:** without it the container has its own isolated
filesystem. `-v src:dst` is how a scanner sees your code and how you get
its report back.

| | Volume | Bind mount |
|---|---|---|
| Path | `/var/lib/docker/volumes/<name>/_data`, Docker-managed | any absolute host path |
| Created by | `docker volume create` (or implicitly) | nothing, the path just has to exist |
| Typical use | databases, production state | dev: live-editing source, **scanners in CI** |
| Risk | low | `-v /:/host` or `-v /var/run/docker.sock:...` gives the container host root |

Docker's guidance: bind mounts in development, volumes in production
(<https://docs.docker.com/develop/dev-best-practices>). Also see `tmpfs`
mounts for in-memory secrets.

## Cleanup
```bash
docker rm -f ubuntu1 ubuntu2; docker volume rm demo
```
