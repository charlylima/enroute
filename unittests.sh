#!/bin/bash

$Qt6_DIR_LINUX/bin/qt-cmake \
    -B build-linux \
    -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_INSTALL_PREFIX=enrouteInstallation \
    -DENABLE_TESTING=ON \
    -G Ninja \
    -S .

# Build only the tests directory
cmake --build build-linux --target tests

# Execute unittests
#ctest --output-on-failure --test-dir build-linux/tests
