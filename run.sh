#!/bin/bash

set -euo pipefail

export QT_VERSION=6.9.0
export PLATFORM=gcc_64

export CURRENT_DIR=$(pwd)
export Qt6_DIR_BASE=/opt/Qt/${QT_VERSION}
export QTDIR=${Qt6_DIR_BASE}/${PLATFORM}
export Qt6_DIR_LINUX=${QTDIR}
export LD_LIBRARY_PATH=${QTDIR}/lib

# Check if $QTDIR exists, abort if not
if [ ! -d "$QTDIR" ]; then
    echo "Error: QTDIR path $QTDIR does not exist. Aborting."
    exit 1
fi

# Helper function to safely create/overwrite symlinks if the destination is a symlink
safe_symlink() {
    local src="$1"
    local dest="$2"
    if [ -L "$dest" ]; then
        rm "$dest"
    fi
    ln -s "$src" "$dest"
}

# Set this variable to 1 to prepare dependencies, 0 to skip
PREPARE_DEPENDENCIES=1
if [ "$PREPARE_DEPENDENCIES" -eq 1 ]; then
    # Prepare dependencies
    pushd .
    cd ../enrouteDependencies
    rm -rf build-maplibre-native-qt-linux
    ./buildscript-linux.sh

    cd Qt/${QT_VERSION}/gcc_64/
    cd include
    for i in * ; do
        safe_symlink "${PWD}/${i}" "$QTDIR/include/$i"
    done
    cd ..
    cd lib
    for i in lib* ; do
        safe_symlink "${PWD}/$i" "$QTDIR/lib/$i"
    done
    cd cmake
    safe_symlink ${PWD}/QMapLibre "$QTDIR/lib/cmake/QMapLibre"
    cd ../..
    cd plugins/geoservices
    for i in * ; do
        safe_symlink "${PWD}/$i" "$QTDIR/plugins/geoservices/$i"
    done
    cd ../..
    cd qml
    safe_symlink ${PWD}/MapLibre "$QTDIR/qml/MapLibre"
    cd ..
    popd
fi

# Compile
pushd .
./buildscript-linux.sh
cmake --install build-linux --prefix install
popd

# Run
cd install
bin/enroute


