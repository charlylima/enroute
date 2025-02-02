ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}
ARG QT_VERSION=6.8.2
ARG ANDROID_NDK_VERSION=26.1.10909125
ARG ANDROID_NDK_VERSION_SHORT=26b
ARG ANDROID_SDK_VERSION=11076708
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0
ARG ANDROID_PLATFORM_VERSION=android-34

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

# Install Android SDK Command-Line Tools
WORKDIR /opt/android
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip -O /tmp/cmdline-tools.zip && \
    mkdir -p /opt/android/sdk/cmdline-tools && \
    unzip -q /tmp/cmdline-tools.zip -d /opt/android/sdk/cmdline-tools && \
    mv /opt/android/sdk/cmdline-tools/cmdline-tools /opt/android/sdk/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip
ENV ANDROID_SDK_ROOT=/opt/android/sdk
ENV PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH
# Install required SDK components
RUN apt-get install -y openjdk-17-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT "platform-tools" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" "platforms;${ANDROID_PLATFORM_VERSION}" "ndk;${ANDROID_NDK_VERSION}"
#RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "ndk;${ANDROID_NDK_VERSION}"
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --uninstall "platforms;android-33-ext4" "platforms;android-33-ext5" "platforms;android-34-ext8" "platforms;android-35-ext14"
ENV ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/${ANDROID_NDK_VERSION}
RUN ln -s ${ANDROID_SDK_ROOT}/ndk /opt/android/ndk
RUN ln -s $ANDROID_NDK_HOME /opt/android/android-ndk-r${ANDROID_NDK_VERSION_SHORT}

# Install Android NDK
#WORKDIR /opt/android
#RUN wget -q https://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux.zip && \
#    unzip android-ndk-r${ANDROID_NDK_VERSION}-linux.zip && \
#    rm android-ndk-r${ANDROID_NDK_VERSION}-linux.zip && \
#    ln -s /opt/android/android-ndk-r${ANDROID_NDK_VERSION} /opt/android-ndk
#ENV ANDROID_NDK_HOME=/opt/android/android-ndk-r${ANDROID_NDK_VERSION}

# Install Qt for Android
WORKDIR /root
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
ENV PLATFORM=gcc_64
WORKDIR /home/${USER_NAME}/enrouteDependencies
RUN $QTDIR/bin/qt-cmake \
    -S maplibre-native-qt \
    -B build-maplibre-native-qt-linux \
    -G Ninja \
    -DMLN_QT_WITH_INTERNAL_ICU=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_PREFIX_PATH=${QTDIR}/lib/cmake/Qt6 \
    -DCMAKE_INSTALL_PREFIX=/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/${PLATFORM}
RUN cmake --build build-maplibre-native-qt-linux
RUN cmake --install build-maplibre-native-qt-linux
ENV QMapLibre_DIR=/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/${PLATFORM}/lib/cmake
ENV QML2_IMPORT_PATH=$QTDIR/qml:/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/${PLATFORM}/qml
ENV QT_PLUGIN_PATH=$QTDIR/plugins:/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/${PLATFORM}/plugins
ENV LD_LIBRARY_PATH=/opt/qt/${QT_VERSION}/${PLATFORM}/lib:/home/docker/enrouteDependencies-bin/Qt/${QT_VERSION}/${PLATFORM}/lib

# Ensure the module is available in the Qt installation
# RUN ln -s $installDir/lib/cmake/QMapLibre /opt/Qt/${QT_VERSION}/${PLATFORM}/lib/cmake/QMapLibre

# enrouteDependencies for Android
ENV PLATFORM=android_arm64_v8a
ENV installDir=/home/${USER_NAME}/enrouteDependencies-bin/Qt/${QT_VERSION}/${PLATFORM}
# first build libzip for the platform
RUN $Qt6_DIR_BASE/$PLATFORM/bin/qt-cmake \
    -G Ninja  \
    -S libzip \
    -B build-libzip-$PLATFORM \
    -DBUILD_DOC=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_REGRESS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TOOLS=OFF \
    -DENABLE_BZIP2=OFF \
    -DENABLE_LZMA=OFF \
    -DENABLE_ZSTD=OFF \
    -DQT_ANDROID_ABIS="arm64-v8a" \
    -DCMAKE_INSTALL_PREFIX=$installDir
RUN cmake --build build-libzip-$PLATFORM
RUN cmake --install build-libzip-$PLATFORM
ENV CMAKE_MODULE_PATH=$CMAKE_MODULE_PATH:$installDir/lib/cmake

RUN $Qt6_DIR_BASE/$PLATFORM/bin/qt-cmake \
    -S maplibre-native-qt \
    -B build-maplibre-native-qt-$PLATFORM \
    -G Ninja \
    -DBUILD_TESTING=OFF \
    -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_PREFIX_PATH=$Qt6_DIR_ANDROID \
    -DQT_ANDROID_ABIS="arm64-v8a" \
    -DCMAKE_INSTALL_PREFIX=$installDir
RUN cmake --build build-maplibre-native-qt-$PLATFORM
RUN cmake --install build-maplibre-native-qt-$PLATFORM
ENV CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:$Qt6_DIR_BASE/$PLATFORM:/home/developer/enrouteDependencies-bin/Qt/${QT_VERSION}/${PLATFORM}

# build enroute
#USER docker
#WORKDIR /home/docker
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
#USER docker
#WORKDIR /home/docker/enroute
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
