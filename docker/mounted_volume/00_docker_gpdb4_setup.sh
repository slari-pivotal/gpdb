#!/bin/bash

set -e

GPDB4_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_SCRIPT_SRC_DIR=$GPDB4_DIR/docker/mounted_volume

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <name of container>"
    echo note: will destroy any container already existing with that name.
    exit 1
else
    DOCKER_NAME=$1
fi

echo $DOCKER_NAME

docker pull pivotaldata/centos-gpdb-dev:5-gcc4.4-happy

pushd $GPDB4_DIR
    git submodule update --init --recursive
popd

set +e
    docker rm $DOCKER_NAME > /dev/null 2>&1
set -e

## Note that the -v switch is used to mount the OS X’s gpdb4 folder into the container
## The privileged and seccomp flags are used to allow gdb to work in Docker (forum post)
docker create --name $DOCKER_NAME -t -v $GPDB4_DIR:/home/gpadmin/gpdb4_mount --privileged --security-opt seccomp:unconfined -i pivotaldata/centos-gpdb-dev:5-gcc4.4-happy bash
docker start $DOCKER_NAME
docker cp $DOCKER_SCRIPT_SRC_DIR/01_root_docker_setup.sh $DOCKER_NAME:/tmp/
docker cp $DOCKER_SCRIPT_SRC_DIR/02_docker_gpdb4_setup.sh $DOCKER_NAME:/tmp/
docker cp $DOCKER_SCRIPT_SRC_DIR/03_gpadmin_docker_compile.sh $DOCKER_NAME:/tmp/

docker exec $DOCKER_NAME /bin/sh - /tmp/01_root_docker_setup.sh
docker exec $DOCKER_NAME /bin/su - gpadmin -c /tmp/02_docker_gpdb4_setup.sh

docker stop $DOCKER_NAME
docker commit ${DOCKER_NAME} gpdb4-image:base
docker start $DOCKER_NAME

docker exec $DOCKER_NAME /bin/su - gpadmin -c /tmp/03_gpadmin_docker_compile.sh



