#!/bin/bash

REGISTRY="gitea.prod.priv.lagovistatech.com"
IMAGE="infotech/keycloak"
TAG="latest"

podman create --name keycloak -p 8080:8080 "$REGISTRY/$IMAGE:$TAG"
podman start keycloak