# Compiling Enroute in the Docker container

* Install docker

  On Ubuntu Linux:
  ```
  sudo apt-get install docker.io
  ```

* Build the Docker Container
  ```
  docker/docker-build-container-image.sh
  ```

* Compile Enroute
  ```
  docker/docker-compile-enroute.sh
  ```

* Run Enroute
  ```
  docker/docker-run-enroute.sh
  ```

* You can also run a shell in the Docker Container:
  ```
  docker/docker-run-container-interactive.sh
  ```
