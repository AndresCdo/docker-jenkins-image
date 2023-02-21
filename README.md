# Jenkins automation

This is the definition for a Jenkins container.

## Usage
Build the image using:

````sh
docker build -t jenkins-image:1.0 .
````

Run and mount volumes using:

````sh
docker run -u 0 -d --restart unless-stopped -p 8000:8080 -p 50000:50000 -v $HOME/jenkins-practice/jenkins_home:/var/jenkins_home jenkins-image:1.0
````
