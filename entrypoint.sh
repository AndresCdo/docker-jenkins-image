#!/bin/bash

# Function to handle the SIGINT signal (Ctrl+C)
handle_sigint() {
  echo "Received SIGINT signal. Exiting..."
  exit 0
}

# Register the handle_sigint function to handle SIGINT signal
trap handle_sigint SIGINT

# Execute the original Jenkins entrypoint command in the background
/usr/bin/tini -- /usr/bin/jenkins --httpPort=8080 &

# PID of the Jenkins process
JENKINS_PID=$!

# Wait for Jenkins to initialize (or you could wait for a specific log line instead of a fixed sleep)
sleep 30

# Set the environment variables
set -a
source /var/jenkins_home/.env
set +a

# Execute your script here (make sure it is executable and available in the container)
bash setup_jenkins_plugins.sh
bash -c "echo 'Jenkins is starting...'"
bash -c "echo 'Jenkins is ready!'"

# Wait for the Jenkins process to complete, allowing signal handling to work correctly
wait $JENKINS_PID
