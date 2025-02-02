#/bin/bash
cd "$(dirname "$0")"
docker build \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) \
    -t qtos663 .

#docker buildx create --use
#docker buildx build --build-arg "USER_NAME=$(id -un)" --build-arg USER_ID=$(id -u) --build-arg "GROUP_NAME=$(id -gn)" --build-arg GROUP_ID=$(id -g) -t qtos663 .
