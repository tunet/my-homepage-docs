#!/usr/bin/env bash

docker --context $MY_HOMEPAGE_DOCKER_CONTEXT compose -f .docker/docker-deploy-stack.yaml pull

docker --context $MY_HOMEPAGE_DOCKER_CONTEXT stack rm docs

docker --context $MY_HOMEPAGE_DOCKER_CONTEXT stack deploy -c .docker/docker-deploy-stack.yaml docs
