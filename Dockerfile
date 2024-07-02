# Use a smaller base image
FROM openjdk:17-jdk-slim as builder

# Install necessary packages
RUN apt-get update && \
    apt-get install -y curl gnupg2 git

# Download and install Jenkins LTS version
RUN curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null && \
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null && \
    apt-get update && \
    apt-get install -y jenkins

# Install necessary package
RUN apt-get install -y fontconfig

# Clean up unnecessary files and directories
RUN apt-get remove -y gnupg2 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

FROM builder as runner

# Set the working directory
WORKDIR /var/jenkins_home

# Print out the version of Jenkins
RUN echo "Jenkins version: $(/usr/bin/jenkins --version)"

# Install Ansible
RUN apt-get update && \
    apt-get install -y sudo wget jq python3 python3-pip && \
    pip3 install ansible 

# # Clone aprovisioning repository
# RUN git clone https://github.com/AndresCdo/ansible-practice/
# RUN rm -rf /var/jenkins_home/ansible-practice/.git 
# RUN sed -i 's/#connection\:/connection\:/' /var/jenkins_home/ansible-practice/playbook.yml
# RUN echo "localhost" > /var/jenkins_home/ansible-practice/hosts
# RUN ansible-playbook /var/jenkins_home/ansible-practice/playbook.yml -i /var/jenkins_home/ansible-practice/hosts -v 

# Clear the cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set the volume mount point for Jenkins
VOLUME /var/jenkins_home

# Expose port 7364
EXPOSE 8080

COPY .env /var/jenkins_home/
COPY setup_jenkins_plugins.sh /var/jenkins_home/
COPY plugins.txt /var/jenkins_home/

# Copy the entrypoint script into the container
COPY entrypoint.sh /var/jenkins_home/

# Add executable permissions to the entrypoint.sh script
RUN chmod +x /var/jenkins_home/entrypoint.sh

# Set the permissions for the entrypoint.sh script
RUN chown jenkins:root /var/jenkins_home/entrypoint.sh

# Add the Jenkins user to the root group
RUN usermod -aG root jenkins

# Set the permissions for the Jenkins home directory
RUN chown -R jenkins:root /var/jenkins_home

# Set the permissions for the Jenkins home directory
RUN chmod -R 775 /var/jenkins_home

# Set the user to the Jenkins user
USER jenkins

ENTRYPOINT ["/var/jenkins_home/entrypoint.sh"]
