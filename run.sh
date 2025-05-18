#!/bin/bash

export QT_VERSION=6.9.0

export CURRENT_DIR=$(pwd)
export PLATFORM=gcc_64
export QTDIR=/opt/Qt/${QT_VERSION}/gcc_64
export Qt6_DIR_BASE=/opt/Qt/${QT_VERSION}
export Qt6_DIR_LINUX=/opt/Qt/${QT_VERSION}/gcc_64
export QMapLibre_DIR=${CURRENT_DIR}/../enrouteDependencies/Qt/${QT_VERSION}/gcc_64/lib/cmake/QMapLibre
export LD_LIBRARY_PATH=/opt/Qt/${QT_VERSION}/gcc_64/lib:${CURRENT_DIR}/../enrouteDependencies/Qt/${QT_VERSION}/gcc_64/lib/
export QML2_IMPORT_PATH=$QTDIR/qml:${CURRENT_DIR}/../enrouteDependencies/Qt/${QT_VERSION}/${PLATFORM}/qml
export QT_PLUGIN_PATH=$QTDIR/plugins:${CURRENT_DIR}/../enrouteDependencies/Qt/${QT_VERSION}/${PLATFORM}/plugins

# pushd .
# cd enrouteDependencies
# rm -rf build-maplibre-native-qt-linux
# ./buildscript-linux.sh
# popd

pushd .
./buildscript-linux.sh
cmake --install build-linux --prefix install
popd

cd install
bin/enroute


