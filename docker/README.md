# Compiling Enroute in the Docker container

Compiling Enroute on your Linux computer is not always easy, especially if you use more than one computer, first you would need to install all dependencies in a compatible version.

With this development docker, you get an Ubuntu environment preconfigured to compile and run Enroute.

## How to use

* Install docker

  On Ubuntu Linux:
  ```bash
  sudo apt-get install docker.io
  sudo usermod -aG docker $USER
  newgrp docker
  ```

* Clone the enroute git repo

  ```bash
  git clone --recursive https://github.com/Akaflieg-Freiburg/enroute.git
  cd enroute
  ```  

* Build the Docker Container
  ```bash
  docker/docker-build-container-image.sh
  ```

* Compile Enroute
  ```bash
  docker/docker-compile-enroute.sh
  ```

* Run Enroute
  ```bash
  docker/docker-run-enroute.sh
  ```

* You can also run a shell in the Docker Container:
  ```bash
  docker/docker-interactive.sh
  ```

## Enroute on MS Windows with WSL2
It also works on MS Windows inside WSL2.
First install Ubuntu in WSL2 according to the documentation of Microsoft. 
Then follow the instructions above for Ubuntu Linux.
There is a wayland display server running in WSL2. 
This way you can compile and run Enroute as a graphical application on MS Windows. 

## Troubleshooting

* Permission Denied Errors: 
  Ensure your user is added to the docker group.

