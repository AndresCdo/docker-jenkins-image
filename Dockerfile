# Use a smaller base image
FROM openjdk:11-jdk-slim

# Install necessary packages
RUN apt-get update && \
    apt-get install -y wget gnupg2 git

# Download and install Jenkins LTS version
RUN wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add - && \
    echo "deb https://pkg.jenkins.io/debian-stable binary/" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y jenkins
RUN apt-get install -y fontconfig

# Clean up unnecessary files and directories
RUN apt-get remove -y wget gnupg2 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose port 8080
EXPOSE 8080

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

# Start Jenkins using Tini as the entrypoint
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/bin/jenkins"]
CMD ["--httpPort=8080"]
