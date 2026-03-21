#!/usr/bin/env bash

set -xe

tag="ubuntu-go:latest"

if [[ $(docker images $tag --format "{{.Repository}}:{{.Tag}}") == "" ]]; then
  docker build -t $tag .
  clear
fi

go build

rm config-manager

docker run --network=host --rm -v $(pwd):/go/src/app -w /go/src/app $tag go run . -install
