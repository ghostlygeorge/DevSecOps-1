# Lab 09: Running and Using a Docker Registry

## Goal
Build an image, run a private registry, tag, push, and query it. This is
the same flow the CI `release` job and the Ansible deploy lab use against
the GitLab registry.

```bash
git clone https://gitlab.practical-devsecops.training/pdso/django.nv && cd django.nv
docker build -t django.nv:1.0 .

docker run -d -p 5000:5000 --restart=always --name registry registry:2
docker tag django.nv:1.0 localhost:5000/django.nv:1.0      # REGISTRY/IMAGE:TAG
docker push localhost:5000/django.nv:1.0
curl localhost:5000/v2/_catalog                            # {"repositories":["django.nv"]}
curl localhost:5000/v2/django.nv/tags/list
docker pull localhost:5000/django.nv:1.0
```

The registry hostname **is part of the image name**. `docker push` goes to
whatever host prefixes the name (Docker Hub when there's no prefix).

## Authenticated registries (later labs)

```bash
echo "pdso-training" | docker login --username root --password-stdin $REGISTRY_HOST
docker build -t $REGISTRY_HOST/django.nv:1.0 .     # build + tag in one go
docker push $REGISTRY_HOST/django.nv:1.0
```

`no basic auth credentials` means you aren't logged in. `--password-stdin`
keeps the password out of `ps` and shell history (`-p` doesn't). After
login, the credential is stored **unencrypted** in `~/.docker/config.json`
unless you configure a credential helper.

In GitLab CI use predefined variables (no secrets to create):

```bash
echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

## Notes
- `registry:2` here has **no TLS and no auth**. Fine on localhost, never on
  a network. Docker only allows plain-HTTP registries for `localhost` or
  ones listed under `insecure-registries`.
- Tag with the commit SHA, not `latest`, so deploys are traceable and
  rollbacks are exact.
