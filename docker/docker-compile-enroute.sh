#!/bin/bash

cd "$(dirname "$0")/.."

# Create the necessary directories
if [ ! -d "$HOME/.ccache" ]; then mkdir -p "$HOME/.ccache"; fi
if [ ! -d "$HOME/.local/share/Akaflieg Freiburg/enroute flight navigation" ]; then mkdir -p "$HOME/.local/share/Akaflieg Freiburg/enroute flight navigation"; fi
if [ ! -d "$HOME/.config/Akaflieg Freiburg/enroute flight navigation" ]; then mkdir -p "$HOME/.config/Akaflieg Freiburg/enroute flight navigation"; fi

# Run the build in the Docker container
docker run --rm \
    -v .:/home/docker/enroute \
    -v $HOME/.ccache:/home/docker/.ccache \
    -v $HOME/.config/Akaflieg\ Freiburg:/home/docker/.config/Akaflieg\ Freiburg \
    -v $HOME/.local/share/Akaflieg\ Freiburg:/home/docker/.local/share/Akaflieg\ Freiburg \
    enroute-dev-linux bash -c "cd ~/enroute && 
        cmake \
            -B build-linux \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
            -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
            -DCMAKE_INSTALL_PREFIX=enrouteInstallation \
            -G Ninja \
            -DCMAKE_C_COMPILER=clang \
            -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_CXX_STANDARD=17 \
            -S .

        cmake --build build-linux && \
        cmake --install build-linux
        "
