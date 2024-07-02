# Jenkins Server Docker Image

This repository contains a Dockerfile to build a lightweight Jenkins server image based on the OpenJDK 17 slim image. The image is intended to be used as a base image for Jenkins servers that require additional customization or configuration.

## Prerequisites

- Docker installed on your machine. You can download Docker from the [Docker website](https://www.docker.com/get-started).
- Basic knowledge of Docker and Docker commands.

## Building the Image

To build this Docker image, run the following command in the directory containing the Dockerfile:
  
    ````sh
    docker build -t jenkins-server .
    ````

This command will build the Docker image and tag it as `jenkins-server`.

## Running the Image

To start a container using the image, run the following command:

    ````sh
    docker run -u 0 -d --restart unless-stopped -p 8080:8080 -p 50000:50000 --name jenkins-server jenkins-server
    ````

This will start a Jenkins server and expose the web interface on port 8080 and the JNLP (Java Web Start) port on port 50000. You can access the Jenkins web interface by navigating to `http://localhost:8080` in your web browser. The default username and password are `admin` and `admin`. Modify the .env file to change the username and password.

## Customization

The Dockerfile installs the necessary packages and prerequisites for Jenkins, including OpenJDK 17. You can customize the Dockerfile by adding or removing packages to suit your needs. You can also add additional configuration files or scripts to the image to automate the setup of Jenkins. Modify the pluggin.txt file to add or remove plugins.

## Contributing

If you have any suggestions, improvements, or issues, please open an issue or a pull request on GitHub.

## License

This project is licensed under the MIT License.
