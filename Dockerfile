# Use a smaller base image
FROM openjdk:11-jdk-slim as builder

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
RUN apt-get remove -y wget gnupg2 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

FROM builder as runner

# Print out the version of Jenkins
RUN echo "Jenkins version: $(/usr/bin/jenkins --version)"

# Add the Jenkins user to the root group
RUN usermod -aG root jenkins

# Set the user to use when running this image
USER jenkins

# Set the working directory
WORKDIR /var/jenkins_home

# Set the volume mount point for Jenkins
VOLUME /var/jenkins_home

# Expose port 7364
EXPOSE 8080

# Set the umask to 077 for security reasons
RUN umask 077

# Set the default command to execute
# Start Jenkins using Tini as the entrypoint
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/bin/jenkins"]
CMD ["--httpPort=8080"]
