# Lab 10: Docker Networking — bridge, host, macvlan, none

## Goal
Understand the network drivers, and why `--network none` is a cheap
hardening control for offline jobs.

| Driver | Behaviour |
|---|---|
| **bridge** (default) | private subnet. Containers on the same bridge talk to each other. Outbound via NAT. |
| **host** | shares the host's network stack. No isolation. Ports are the host's ports. |
| **macvlan** | each container gets its own MAC on the parent NIC and looks like a physical host on the LAN. Misconfigured, it can flood the network with MACs or duplicate IPs. |
| **none** | loopback only, no network at all |

```bash
docker network --help
docker network ls                       # bridge, host, none exist by default
```

## bridge

```bash
docker network create mynetwork
docker inspect mynetwork                 # IPAM.Config: Subnet 172.19.0.0/16, Gateway 172.19.0.1
docker run -d --name ubuntu --network mynetwork -it ubuntu:20.04
docker inspect mynetwork                 # "Containers": {...ubuntu 172.19.0.2...}
docker exec ubuntu apt update            # works: NAT + DNS
docker rm -f ubuntu; docker network rm mynetwork
```

User-defined bridges also give **DNS by container name**. The default
`bridge` network doesn't:

```bash
docker network create appnet
docker run -d --name web --network appnet nginx
docker run --rm --network appnet alpine wget -qO- http://web | head -3
docker rm -f web; docker network rm appnet
```

## macvlan

```bash
docker network create --driver macvlan mymacvlan       # optionally -o parent=eth0 --subnet ...
docker network list
ifconfig                                               # a dm-<id> interface appears
docker run -d --name ubuntu --network mymacvlan -it ubuntu:20.04
docker inspect ubuntu -f "{{json .NetworkSettings.Networks }}" | jq
docker rm -f ubuntu; docker network rm mymacvlan
```

**bridge vs macvlan:** bridge puts containers behind a host-side virtual
switch + NAT (they share the host's IP to the outside). macvlan gives each
container its own MAC/IP directly on the physical network, with no NAT and
no port publishing, but by default the host can't talk to its own macvlan
containers.

## none

```bash
docker run -d --name ubuntu --network=none -it ubuntu:20.04
docker inspect ubuntu -f "{{json .NetworkSettings.Networks }}" | jq    # empty IP/Gateway
docker exec ubuntu apt update     # Temporary failure resolving 'archive.ubuntu.com'
docker rm -f ubuntu
```

Use `--network none` for SAST/secret scanners that work offline
(bandit, gitleaks, hadolint): they can't exfiltrate your source code even
if the image is compromised.
