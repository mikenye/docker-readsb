#!/bin/sh

ARCH=`uname -m`
IMAGE=mikenye/readsb

# Make architecture names match docker 'standards' (https://docs.docker.com/docker-for-mac/multi-arch/)
if [ ${ARCH} = "aarch64" ]; then
    ARCH="arm64v8"
fi
if [ ${ARCH} = "x86_64" ]; then
    ARCH="amd64"
fi
if [ ${ARCH} = "armv7l" ]; then
    ARCH="arm32v7"
fi

# Check if target dockerfile exists
if [ -f "Dockerfile.${ARCH}" ]; then
    # Build
    echo Building from Dockerfile.${ARCH}
    docker build -f Dockerfile.${ARCH} -t ${IMAGE}:development-${ARCH} . && \
    VERSION=`docker run --rm -it --entrypoint /usr/local/bin/readsb mikenye/readsb:development-amd64 -V | tr -s " " | tr -d "\r" | tr -d "\n" | cut -d " " -f 2` && \
    echo Tagging as ${IMAGE}:${VERSION}-${ARCH} && \
    docker tag ${IMAGE}:development-${ARCH} ${IMAGE}:${VERSION}-${ARCH}
else
    echo Target file Dockerfile.${ARCH} does not exist!
fi



