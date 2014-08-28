#!/usr/bin/env bash

set -e
set -u

DOCKER_IMAGE_NAME='springersbm/ml-materials'
DEPRECATED_DOCKER_IMAGE_NAME='patforna/ml-configured'

run() {
    echo "Starting $DOCKER_IMAGE_NAME container ..."
    docker run -d --name marklogic -p 7654:7654 -p 7655:7655 -p 8000:8000 -p 8001:8001 -p 8002:8002 -p 8400:8400 -p 8401:8401 -p 8403:8403 -p 9999:9999 "$DOCKER_IMAGE_NAME"
}

stopAndRm() {
    for id in `docker ps -aq`
    do
	containerInfo=`docker inspect "$id"`
	imageName=`echo "$containerInfo"|grep Image|head -1|cut -f4 -d'"'`
	running=`echo "$containerInfo"|grep Running| sed "s/.*: //"|sed "s/,//"`
	if [ "$imageName" == "$DOCKER_IMAGE_NAME" ] || [ "$imageName" == "$DEPRECATED_DOCKER_IMAGE_NAME" ]; then
		if [ "$running" == "true" ]; then
        		echo "Stopping $DOCKER_IMAGE_NAME container $id ..."
			docker stop $id
		fi
        	echo "Removing $DOCKER_IMAGE_NAME container $id ..."
		docker rm $id
	fi
    done
}

stopAndRun() {
    stopAndRm
    run
}

pull() {
    echo "Checking for updates to $DOCKER_IMAGE_NAME ..."
    docker pull "$DOCKER_IMAGE_NAME" > /dev/null
}

localRepoImageId() {
    docker images -q "$DOCKER_IMAGE_NAME"
}

runningContainerId() {
    docker ps|grep "$DOCKER_IMAGE_NAME" | cut -f1 -d' ' 
}

containerImageId() {
    if [ "$1" != "" ]; then
        containerId=$1
        docker inspect "$containerId" | grep Image | tail -1 | cut -f4 -d'"' | cut -c1-12
    fi
}

needsRestart() {
    rcid=`runningContainerId`
    cid=`containerImageId "$rcid"`
    lriid=`localRepoImageId`
    if [ "$cid" != "$lriid" ]; then
        return 0
    else 
        return 1
    fi
}

dieIfNoDocker() {
    command -v docker >/dev/null 2>&1 || { echo >&2 "Can't find docker."; exit ; }
}

dieIfNoDocker
pull
if needsRestart; then  
    stopAndRun
else
    echo "Docker image is up to date"
fi

