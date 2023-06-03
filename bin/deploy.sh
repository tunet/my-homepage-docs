#!/usr/bin/env bash

hdocker compose -f .docker/docker-deploy-stack.yaml pull

hdocker stack rm docs

hdocker stack deploy -c .docker/docker-deploy-stack.yaml docs
