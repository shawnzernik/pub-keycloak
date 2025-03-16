#!/bin/bash

REGISTRY="gitea.prod.priv.lagovistatech.com"
IMAGE="infotech/keycloak"
TAG="latest"

#podman build --squash-all --no-cache -t "$REGISTRY/$IMAGE:$TAG" .
podman build --squash-all -t "$REGISTRY/$IMAGE:$TAG" .
podman login --tls-verify=false "$REGISTRY"
podman push --tls-verify=false "$REGISTRY/$IMAGE:$TAG"
