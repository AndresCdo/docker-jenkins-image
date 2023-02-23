#Importing base image Ubuntu
FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive
#Updating and Upgrading Ubuntu
RUN apt-get update 
RUN apt-get -y upgrade
#Installing Basic Packages & Utilities in Ubuntu
# RUN apt-get -y install software-properties-common git gnupg sudo nano vim wget curl zip unzip build-essential libtool autoconf uuid-dev pkg-config libsodium-dev lynx-common tcl inetutils-ping net-tools ssh openssh-server openssh-client openssl letsencrypt apt-transport-https telnet locales gdebi lsb-release
RUN apt-get install software-properties-common -y
# Add the repository
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update
#Clear cache
RUN apt-get clean
#Jenkins Prerequisites
# RUN apt-get search openjdk
#Install Java version 11 as prerequisite
RUN apt-get install openjdk-11-jdk -y
RUN apt-get install ca-certificates wget -y && apt-get clean
#Jenkins installation
#Download & add repository key
RUN wget --no-check-certificate -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
#Getting binary file into /etc/apt/sources.list.d
RUN sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
#Updating packages
RUN apt-get update
#Installing Jenkins
RUN apt-get install jenkins -y
#Start jenkins
RUN service jenkins start
#Expose port 8080
EXPOSE 8080

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
# RUN whereis jenkins
CMD [ "/usr/bin/tini", "--", "/usr/bin/jenkins" ]
