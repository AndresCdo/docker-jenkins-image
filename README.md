# Jenkins Server Docker Image

This repository contains a Dockerfile to build a lightweight Jenkins server image based on Ubuntu.

## Usage

To build the image, run the following command:

````sh
docker build -t jenkins-server:1.0 .
````

To start a container using the image, run the following command:

````sh
docker run -u 0 -d --restart unless-stopped -p 8000:8080 -p 50000:50000 -v $HOME/jenkins-practice/jenkins_home:/var/jenkins_home jenkins-server:1.0
````
This will start a Jenkins server and expose the web interface on port 8080 and the JNLP port on port 50000.

## Customization

The Dockerfile installs the necessary packages and prerequisites for Jenkins, including OpenJDK 11. You can customize the Dockerfile by adding or removing packages to suit your needs.

## License

This project is licensed under the MIT License.
