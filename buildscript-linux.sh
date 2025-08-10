#!/bin/bash

#
# This script builds "enroute flight navigation" for the Linux desktop in
# "Debug" mode.  Several sanitizers are switched on.
#
# See https://github.com/Akaflieg-Freiburg/enroute/wiki/Build-scripts
#

#
# Copyright © 2020 Stefan Kebekus <stefan.kebekus@math.uni-freiburg.de>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA 02111-1307, USA.
#
#
# Run this script in the main directory tree.

# Configure this script to exit immediately if a command exits with a non-zero status
set -e

# You should make sure that git submodules are loaded
# git submodule update --init --recursive

# Set the Qt6_DIR_LINUX variable to point to your Qt6 installation.
# For example, if you have Qt6 installed in /opt/Qt/6.9.0/gcc_64,
# you would set it like this:
# export Qt6_DIR_LINUX=/opt/Qt/6.9.0/gcc_64
if [ -z "$Qt6_DIR_LINUX" ]; then
    echo "Error: Qt6_DIR_LINUX is not set. Please export Qt6_DIR_LINUX to your Qt6 installation path."
    echo "Example: export Qt6_DIR_LINUX=/opt/Qt/6.9.0/gcc_64"
    echo "If you have not installed Qt6, please do so first. Download Qt from https://www.qt.io/download."
    exit 1
fi

# Clean
# Call with "-no-clean" parameter for a faster build.
if [ "$1" != "-no-clean" ] && [ "$2" != "-no-clean" ]; then
    rm  -rf build-linux
    rm  -rf enrouteInstallation
fi

# Build the executable
$Qt6_DIR_LINUX/bin/qt-cmake \
    -B build-linux \
    -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_INSTALL_PREFIX=enrouteInstallation \
    -G Ninja \
    -S .

cmake --build build-linux

# Call with "-run" parameter to run the executable
if [ "$1" = "-run" ] || [ "$2" = "-run" ]; then
    # Run from build folder (MapLibre plugins are now copied automatically by CMake)
    build-linux/src/enroute
fi

# Call with "-install" parameter to install and run from installation directory
if [ "$1" = "-install" ] || [ "$2" = "-install" ]; then
    # Install the executable (vendor symlink is created automatically by CMake)
    cmake --install build-linux
    # Run from installation directory
    cd enrouteInstallation && ./bin/enroute
fi
