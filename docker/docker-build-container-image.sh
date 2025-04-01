#/bin/bash

cd "$(dirname "$0")"

#docker build \
#    --build-arg USER_ID=$(id -u) \
#    --build-arg GROUP_ID=$(id -g) \
#    -t enroute-dev .

docker build \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) \
    --build-arg HTTP_PROXY=$HTTP_PROXY \
    --build-arg HTTPS_PROXY=$HTTPS_PROXY \
    --build-arg NO_PROXY=$NO_PROXY \
    -t enroute-dev-linux -f Dockerfile.linux .

docker build \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) \
    --build-arg HTTP_PROXY=$HTTP_PROXY \
    --build-arg HTTPS_PROXY=$HTTPS_PROXY \
    --build-arg NO_PROXY=$NO_PROXY \
    -t enroute-dev-android -f Dockerfile.android .
