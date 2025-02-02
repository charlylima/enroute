#/bin/bash

cd "$(dirname "$0")"

#docker build \
#    --build-arg USER_ID=$(id -u) \
#    --build-arg GROUP_ID=$(id -g) \
#    -t enroute-dev .

docker build \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) \
    -t enroute-dev-linux -f Dockerfile.linux .

docker build \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) \
    -t enroute-dev-android -f Dockerfile.android .
