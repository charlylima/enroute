ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}
ARG QT_VERSION=6.8.2
ARG ANDROID_NDK_VERSION=25c
ARG USER_NAME=docker
ARG USER_ID
ARG GROUP_NAME=docker
ARG GROUP_ID

# set locale
RUN apt-get update && apt-get install -y locales
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential gcc g++ clang clangd cmake extra-cmake-modules git wget ccache ninja-build doxygen graphviz \
    unzip zipcmp zipmerge ziptool libzip-dev \
    libfreetype6 libstdc++6 libncurses6 \
    libssl-dev libcurl4-openssl-dev libboost-dev libboost-thread-dev libglib2.0-dev libfontconfig1-dev libdbus-1-dev libinput-dev \
    libsqlite3-dev libpng-dev libjpeg-dev libevent-dev libpulse-dev libpipewire-0.3-dev libicu-dev \
    libgl1-mesa-dev libglu1-mesa-dev libegl1-mesa-dev freeglut3-dev mesa-common-dev \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 libxkbcommon0 libxcb-cursor0 \
    speech-dispatcher appstream  fuse  spirv-tools

# configure apt build dependencies and install
RUN cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu-src.sources && sed -i 's/Types: deb/Types: deb-src/' /etc/apt/sources.list.d/ubuntu-src.sources && apt-get update && apt-get build-dep -y qt6-base-dev

# Install Qt from sourcecode
# RUN wget https://download.qt.io/official_releases/qt/6.6/${QT_VERSION}/single/qt-everywhere-src-${QT_VERSION}.tar.xz
# RUN tar -xf qt-everywhere-src-${QT_VERSION}.tar.xz
# WORKDIR /qt-everywhere-src-${QT_VERSION}
# RUN ./configure -prefix /opt/qt/${QT_VERSION}/gcc_64 -opensource -confirm-license
# RUN cmake --build . --parallel
# RUN cmake --install .

# Install Qt with aqt: https://aqtinstall.readthedocs.io/en/latest/getting_started.html#installing-qt
WORKDIR /root
RUN apt-get install -y python3 python3-pip pipx
RUN pipx ensurepath && pipx install aqtinstall
RUN python3 -m venv venv && . venv/bin/activate
RUN /root/.local/bin/aqt install-qt linux desktop ${QT_VERSION} gcc_64 -m all -O /opt/qt
ENV QTDIR=/opt/qt/${QT_VERSION}/gcc_64
ENV Qt6_DIR_LINUX=$QTDIR
ENV Qt6_DIR_BASE=$QTDIR/..
ENV PATH=$QTDIR/bin:$PATH
ENV LD_LIBRARY_PATH=$Qt6_DIR_LINUX/lib:$LD_LIBRARY_PATH

# Install Android NDK
WORKDIR /opt
RUN wget -q https://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux.zip && \
    unzip android-ndk-r${ANDROID_NDK_VERSION}-linux.zip && \
    rm android-ndk-r${ANDROID_NDK_VERSION}-linux.zip && \
    ln -s /opt/android-ndk-r${ANDROID_NDK_VERSION} /opt/android-ndk && \
    mkdir -p /opt/android && ln -s /opt/android-ndk-r${ANDROID_NDK_VERSION} /opt/android/android-ndk-r25b
ENV ANDROID_NDK_HOME=/opt/android-ndk-r${ANDROID_NDK_VERSION}

# Install Qt for Android
WORKDIR /root
RUN apt-get install -y openjdk-17-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
RUN /root/.local/bin/aqt install-qt linux android ${QT_VERSION} android_arm64_v8a -m all -O /opt/qt
ENV Qt6_DIR_ANDROID=/opt/qt/${QT_VERSION}/android_arm64_v8a
ENV QT_HOST_PATH=$Qt6_DIR_LINUX

# Create a user
# with the same user id and group id as the host user
# so it can access the host files.
# first delete the user if it already exists
RUN if [ "${USER_ID}" -ge 1000 ] && getent passwd ${USER_ID} > /dev/null; then userdel -f $(getent passwd ${USER_ID} | cut -d: -f1); fi
RUN if ! getent group ${GROUP_ID} > /dev/null; then groupadd -g ${GROUP_ID} ${GROUP_NAME}; fi
RUN useradd -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash -m "${USER_NAME}"
RUN apt-get install -y sudo
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}
RUN ln -s /opt/android-ndk
RUN ln -s /opt/qt

# enrouteDependencies for Linux
RUN git clone --recursive https://github.com/Akaflieg-Freiburg/enrouteDependencies.git
WORKDIR /home/${USER_NAME}/enrouteDependencies
RUN $QTDIR/bin/qt-cmake \
    -S maplibre-native-qt \
    -B build-maplibre-native-qt-linux \
    -G Ninja \
    -DMLN_QT_WITH_INTERNAL_ICU=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_PREFIX_PATH=${QTDIR}/lib/cmake/Qt6 \
    -DCMAKE_INSTALL_PREFIX=/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/gcc_64
RUN cmake --build build-maplibre-native-qt-linux
RUN cmake --install build-maplibre-native-qt-linux
ENV QMapLibre_DIR=/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/gcc_64/lib/cmake
ENV QML2_IMPORT_PATH=$QTDIR/qml:/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/gcc_64/qml
ENV QT_PLUGIN_PATH=$QTDIR/plugins:/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/gcc_64/plugins
ENV LD_LIBRARY_PATH=/opt/qt/${QT_VERSION}/gcc_64/lib:/home/docker/enrouteDependencies-bin/Qt/${QT_VERSION}/gcc_64/lib

# Ensure the module is available in the Qt installation
# RUN ln -s $installDir/lib/cmake/QMapLibre /opt/Qt/${QT_VERSION}/gcc_64/lib/cmake/QMapLibre

# enrouteDependencies for Android
#ENV PLATFORM=android_arm64_v8a
#ENV installDir=/opt/enrouteDependencies/Qt/${QT_VERSION}/${PLATFORM}
#RUN $Qt6_DIR_BASE/$PLATFORM/bin/qt-cmake \
#    -G Ninja  \
#    -S libzip \
#    -B build-libzip-$PLATFORM \
#    -DBUILD_DOC=OFF \
#    -DBUILD_EXAMPLES=OFF \
#    -DBUILD_REGRESS=OFF \
#    -DBUILD_SHARED_LIBS=OFF \
#    -DBUILD_TOOLS=OFF \
#    -DENABLE_BZIP2=OFF \
#    -DENABLE_LZMA=OFF \
#    -DENABLE_ZSTD=OFF \
#    -DQT_ANDROID_ABIS="arm64-v8a" \
#    -DCMAKE_INSTALL_PREFIX=$Qt6_DIR_ANDROID
#RUN cmake --build build-libzip-$PLATFORM
#RUN cmake --install build-libzip-$PLATFORM

#RUN $Qt6_DIR_BASE/$PLATFORM/bin/qt-cmake \
#    -S maplibre-native-qt \
#    -B build-maplibre-native-qt-$PLATFORM \
#    -G Ninja \
#    -DBUILD_TESTING=OFF \
#    -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
#    -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
#    -DCMAKE_PREFIX_PATH=$Qt6_DIR_ANDROID \
#    -DQT_ANDROID_ABIS="arm64-v8a" \
#    -DCMAKE_INSTALL_PREFIX=$Qt6_DIR_ANDROID
#RUN cmake --build build-maplibre-native-qt-$PLATFORM
#RUN cmake --install build-maplibre-native-qt-$PLATFORM
#ENV CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:$Qt6_DIR_BASE/$PLATFORM:/home/developer/enrouteDependencies/${installDir}

# build enroute
#USER developer
#WORKDIR /home/developer
#RUN git clone --recursive https://github.com/Akaflieg-Freiburg/enroute.git
#WORKDIR /home/developer/enroute
#RUN mkdir build-linux
#RUN $QTDIR/bin/qt-cmake \
#    -B build-linux \
#    -DCMAKE_INSTALL_PREFIX=enrouteInstallation \
#    -G Ninja \
#    -S .
#RUN cmake --build build-linux

# build enroute for Android
#USER developer
#WORKDIR /home/developer/enroute
#RUN mkdir -p build-android-debug
#RUN $Qt6_DIR_ANDROID/bin/qt-cmake \
#    -S . \
#    -B build-android-debug \
#    -DCMAKE_BUILD_TYPE:STRING=Debug \
#    -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
#    -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
#    -DQT_ANDROID_ABIS="arm64-v8a" \
#    -DQT_HOST_PATH=$Qt6_DIR_LINUX \
#    -G Ninja
#RUN cmake --build build-android-debug

WORKDIR /home/${USER_NAME}/enroute
