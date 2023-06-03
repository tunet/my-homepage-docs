#!/usr/bin/env bash

source .env

docker build \
    -t tunet/docs:latest \
    -f ./.docker/Dockerfile \
    --target frontend \
    --build-arg NGINX_VERSION=${NGINX_VERSION} \
    --build-arg MKDOCS_MATERIAL_VERSION=${MKDOCS_MATERIAL_VERSION} \
    .

docker push tunet/docs:latest
