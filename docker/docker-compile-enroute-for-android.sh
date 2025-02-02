#!/bin/bash

cd "$(dirname "$0")/.."

# Create the necessary directories
if [ ! -d "$HOME/.ccache" ]; then mkdir -p "$HOME/.ccache"; fi

# Run the build in the Docker container
docker run --rm \
    -v .:/home/docker/enroute \
    -v $HOME/.ccache:/home/docker/.ccache \
    enroute-dev-android bash -c "cd ~/enroute && \
        \${Qt6_DIR_ANDROID}/bin/qt-cmake \
            -S . \
            -B build-android-debug \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
            -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
            -Dlibzip_DIR=/home/docker/enrouteDependencies-bin/Qt/6.8.2/android_arm64_v8a/lib/cmake/libzip \
            -DQMapLibre_DIR=/home/docker/enrouteDependencies-bin/Qt/6.8.2/android_arm64_v8a/lib/cmake/QMapLibre \
            -DQT_ANDROID_ABIS="arm64-v8a" \
            -DQT_HOST_PATH=\$QT_HOST_PATH \
            -G Ninja \
            && \ 
        cmake --build build-android \
        "
