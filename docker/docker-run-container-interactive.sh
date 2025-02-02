#!/bin/bash

# Prepare settings for Wayland and X11
if [ -n "$WAYLAND_DISPLAY" ]; then
    QT_QPA_PLATFORM="wayland"
    DOCKER_PARAMETERS="-v /run/user/$(id -u)/wayland-0:/run/user/$(id -u)/wayland-0 -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY "
    # Workaround for MS Windows WSL2, see: 
    # https://github.com/microsoft/WSL/issues/11261
    if [ -e /mnt/wslg/runtime-dir/wayland-0 ] && [ ! -e /run/user/1000/wayland-0 ] || [ -d /run/user/1000/wayland-0 ]; then
        if [ -d /run/user/1000/wayland-0 ]; then
            rmdir /run/user/1000/wayland-0
        fi
        sudo ln -s /mnt/wslg/runtime-dir/wayland-0 /run/user/1000/wayland-0
    fi
else
    QT_QPA_PLATFORM="xcb"
    DOCKER_PARAMETERS="-v /tmp/.X11-unix:/tmp/.X11-unix -v /tmp/.XIM-unix:/tmp/.XIM-unix -e DISPLAY=$DISPLAY "
    # Allow Docker to access the display server
    xhost +local:docker
fi

# Create the necessary directories
if [ ! -d "$HOME/.ccache" ]; then mkdir -p "$HOME/.ccache"; fi
if [ ! -d "$HOME/.local/share/Akaflieg Freiburg/enroute flight navigation" ]; then mkdir -p "$HOME/.local/share/Akaflieg Freiburg/enroute flight navigation"; fi
if [ ! -d "$HOME/.config/Akaflieg Freiburg/enroute flight navigation" ]; then mkdir -p "$HOME/.config/Akaflieg Freiburg/enroute flight navigation"; fi

# Run the Docker container with the appropriate environment variables
docker run --rm -it \
    -v .:/home/docker/enroute \
    -v $HOME/.ccache:/home/docker/.ccache \
    -v $HOME/.config/Akaflieg\ Freiburg:/home/docker/.config/Akaflieg\ Freiburg \
    -v $HOME/.local/share/Akaflieg\ Freiburg:/home/docker/.local/share/Akaflieg\ Freiburg \
    -e QT_QPA_PLATFORM=$QT_QPA_PLATFORM \
    -e LIBGL_ALWAYS_SOFTWARE=1 \
    -e XDG_RUNTIME_DIR=/run/user/$(id -u) \
    -v /dev/dri:/dev/dri --device /dev/dri \
    -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
    $DOCKER_PARAMETERS \
    qtos663 bash
    