#!/bin/bash
#
#
# Docker helper script: build, push, run, bash, stop
# Maintainer: David Ryder
#
# Requires:
# jq - https://stedolan.github.io/jq/download/
#
CMD_LIST=${@:-"help"} # build | build-push | run | bash | stop
if [ -d $DOCKER_TAG_NAME ]; then
  echo "Docker image tag name envvar not set: DOCKER_TAG_NAME"
  echo "export DOCKER_TAG_NAME=..."
  exit 1
fi
#DOCKER_TAG_NAME=${1:-"airflow-test1"}
#DOCKER_REPOSITORY_ACCOUNT=${2:-"NOTSET"}
#DOCKER_REPOSITORY_PWD=${3:-"NOTSET"}

# Check docker: Linux or Ubuntu snap
DOCKER_CMD=`which docker`
DOCKER_CMD=${DOCKER_CMD:-"/snap/bin/microk8s.docker"}
echo "Using: "$DOCKER_CMD
if [ -d $DOCKER_CMD ]; then
    echo "Docker is missing: "$DOCKER_CMD
    exit 1
fi

# Check jq
JQ_CMD=`which jq`
if [ -d $JQ_CMD ]; then
    echo "jq is missing: "$JQ_CMD
    echo "Install jq: https://stedolan.github.io/jq/download/ "
    exit 1
fi

_getDockerContainerId() {
  IMAGE_NAME=${1:-"Image Name Missing"}
  DOCKER_ID=`docker container ps --format '{{json .}}' \
    | jq --arg SEARCH_STR "$IMAGE_NAME" 'select(.Image==$SEARCH_STR)' \
    | jq -s '[.[] | {ID, Names, Image } ][0]' \
    | jq -r .ID`
    echo $DOCKER_ID
}

_getDockerImageId() {
  REPOSITORY_NAME=${1:-"Repository Name Missing"}
  echo "Repository "$REPOSITORY_NAME
  DOCKER_ID=`docker images --format '{{json .}}' \
    | jq --arg SEARCH_STR "$REPOSITORY_NAME" 'select(.Repository==$SEARCH_STR )' \
    | jq -s '[.[] | {Repository, ID} ][0]' \
    | jq -r .ID`
  echo $DOCKER_ID
}

_dockerPrune() {
  $DOCKER_CMD system prune -f
}

_dockerBuild() {
  echo "Building image: "$DOCKER_TAG_NAME
  $DOCKER_CMD build -t $DOCKER_TAG_NAME .
}

_dockerPush() {
  $DOCKER_CMD login -u $DOCKER_REPOSITORY_ACCOUNT -p $DOCKER_REPOSITORY_PWD
  $DOCKER_CMD push $DOCKER_REPOSITORY_TAG_NAME
}

_dockerRun() {
  # Adds ports
  # Adds RW volume on host
  echo "Docker running $DOCKER_TAG_NAME"
  $DOCKER_CMD run --rm --detach   \
            $DOCKER_PORTS         \
            --volume /tmp/dock-$DOCKER_TAG_NAME:/$DOCKER_TAG_NAME:rw \
            -it                \
            $DOCKER_TAG_NAME
}

_dockerWaitUntilRunning() {
  CID="null"
  while [ "$CID" == "null" ];
  do
      echo "Waiting for container to start: $DOCKER_TAG_NAME $CID"
      sleep 1
      CID=$(_getDockerContainerId $DOCKER_TAG_NAME)
  done
  echo "Container Started: $DOCKER_TAG_NAME $CID"
}

_dockerWaitUntilStopped() {
  CID="null"
  while [ "$CID" != "null" ];
  do
      echo "Waiting for container to stop: $DOCKER_TAG_NAME $CID"
      sleep 1
      CID=$(_getDockerContainerId $DOCKER_TAG_NAME)
  done
  echo "Container Stopped: $DOCKER_TAG_NAME $CID"
}

_dockerBash() {
  CID=$(_getDockerContainerId ${DOCKER_TAG_NAME})
  echo "Container ID $CID for ${DOCKER_TAG_NAME}"
  $DOCKER_CMD exec -it $(_getDockerContainerId ${DOCKER_TAG_NAME}) /bin/bash
}

_dockerStop() {
  CONTAINER_ID=`_getDockerContainerId ${DOCKER_TAG_NAME}`
  if [ "$CONTAINER_ID" != "" ]; then
    echo "Stop ${DOCKER_TAG_NAME} ${CONTAINER_ID}"
    docker stop ${CONTAINER_ID} &
    sleep 5 # some time for container to stop
  else
    echo "Container ${DOCKER_TAG_NAME} is not running"
  fi
}

_dockerDeleteImage() {
  IMAGE_ID=`_getDockerImageId ${DOCKER_TAG_NAME}`
  echo ${DOCKER_TAG_NAME} $IMAGE_ID
  if [ "$IMAGE_ID" != "" ]; then
    echo "Deleting image ${DOCKER_TAG_NAME} ${IMAGE_ID}"
    docker rmi ${IMAGE_ID}
  else
    echo "Image ${DOCKER_TAG_NAME} not found"
  fi
}

_runCommand() {
  CMD=${1:-"help"}
  echo "Running [$CMD]"
  if [ $CMD == "build" ]; then
    _dockerBuild
  elif [ $CMD == "prune" ]; then
    _dockerPrune
  elif [ $CMD == "build-push" ]; then
    DOCKER_REPOSITORY_TAG_NAME=$DOCKER_REPOSITORY_ACCOUNT/$DOCKER_TAG_NAME
    echo "Push image to repository $DOCKER_REPOSITORY_ACCOUNT DOCKER_REPOSITORY_TAG_NAME"
    _dockerBuild
    _dockerPush
  elif [ $CMD == "run" ]; then
    _dockerRun
    _dockerWaitUntilRunning
  elif [ $CMD == "bash" ]; then
    _dockerBash
  elif [ $CMD == "stop" ]; then
    _dockerStop
    _dockerWaitUntilStopped
  elif [ $CMD == "delete" ]; then
    _dockerDeleteImage
  elif [ $CMD == "sync" ]; then
    rsync -v -a $SYNC_SRC $SYNC_DST
  else
    echo "Commands: build | prune | build-push | run | bash | stop | delete | sync"
    exit 1
  fi
}

for CMD in $CMD_LIST
do
  _runCommand $CMD
done
