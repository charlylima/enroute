#!/bin/bash
# Build script for Enroute using Qt 6.10.1 with qt-cmake and ninja

set -e  # Exit on error

QT_PATH="/opt/Qt/6.9.3/gcc_64"
QT_CMAKE="${QT_PATH}/bin/qt-cmake"
BUILD_DIR="build-linux"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "Configuring project with qt-cmake..."
"${QT_CMAKE}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_PREFIX_PATH="${QT_PATH}" \
    ..

echo "Building project with ninja..."
ninja

echo "Build completed successfully!"

src/enroute 
