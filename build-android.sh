#!/bin/bash
set -e

# Android build script for enroute
# Requires: Qt 6.9.3 for Android, Android SDK, Android NDK

# Configuration
ANDROID_SDK_ROOT="/opt/android/sdk"
ANDROID_NDK_ROOT="/opt/android/android-ndk-r27c"
QT_ROOT_DIR="/opt/Qt/6.9.3/android_arm64_v8a"
QT_HOST_PATH="/opt/Qt/6.9.3/gcc_64"

# Check if paths exist
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "ERROR: Android SDK not found at $ANDROID_SDK_ROOT"
    exit 1
fi

if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "ERROR: Android NDK not found at $ANDROID_NDK_ROOT"
    exit 1
fi

if [ ! -d "$QT_ROOT_DIR" ]; then
    echo "ERROR: Qt for Android not found at $QT_ROOT_DIR"
    echo "Please install Qt 6.9.3 for android_arm64_v8a"
    exit 1
fi

if [ ! -d "$QT_HOST_PATH" ]; then
    echo "ERROR: Qt host tools not found at $QT_HOST_PATH"
    exit 1
fi

# Export environment variables
export ANDROID_SDK_ROOT
export ANDROID_NDK_ROOT
export QT_HOST_PATH

echo "=========================================="
echo "Android Build Configuration"
echo "=========================================="
echo "Android SDK: $ANDROID_SDK_ROOT"
echo "Android NDK: $ANDROID_NDK_ROOT"
echo "Qt Android:  $QT_ROOT_DIR"
echo "Qt Host:     $QT_HOST_PATH"
echo "=========================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for dependencies directory
if [ ! -d "3rdParty" ]; then
    echo "ERROR: 3rdParty directory not found. Run: git submodule update --init --recursive"
    exit 1
fi

# Build libzip
echo ""
echo "=========================================="
echo "Building libzip..."
echo "=========================================="
rm -rf build-android-libzip-CL
$QT_ROOT_DIR/bin/qt-cmake \
    -S 3rdParty/libzip \
    -B build-android-libzip-CL \
    -G Ninja \
    -DBUILD_DOC=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_REGRESS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TOOLS=OFF \
    -DENABLE_BZIP2=OFF \
    -DENABLE_LZMA=OFF \
    -DENABLE_ZSTD=OFF \
    -DCMAKE_INSTALL_PREFIX=$QT_ROOT_DIR

cmake --build build-android-libzip-CL
cmake --install build-android-libzip-CL
rm -rf build-android-libzip-CL

echo ""
echo "=========================================="
echo "Building enroute for Android..."
echo "=========================================="
rm -rf build-android-CL
$QT_ROOT_DIR/bin/qt-cmake \
    -S . \
    -B build-android-CL \
    -G Ninja \
    -DCMAKE_BUILD_TYPE:STRING=Debug

cmake --build build-android-CL
cmake --build build-android-CL --target apk
cp build-android-CL/src/android-build/build/outputs/apk/debug/android-build-debug.apk enrouteCL.apk

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo "APK location:"
ls -lh enrouteCL.apk 2>/dev/null || echo "APK not found - check build log"
echo "=========================================="

# Copy APK to Windows share
WIN_SHARE="/mnt/c/Users/user/win-share"
if [ -d "$WIN_SHARE" ]; then
    cp enrouteCL.apk "$WIN_SHARE/"
    echo "APK copied to $WIN_SHARE/enrouteCL.apk"
else
    echo "WARNING: Windows share not found at $WIN_SHARE — skipping copy"
fi
