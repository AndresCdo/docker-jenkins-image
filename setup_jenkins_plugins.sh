#! /bin/bash

url=http://localhost:8080
password=$(cat /var/lib/jenkins/.jenkins/secrets/initialAdminPassword)

# Function to check if the previous command was successful
check_status() {
  if [ $? -eq 0 ]; then
    echo "Success"
  else
    echo "Failure"
    exit 1
  fi
}

# Function to get the crumb and cookie
get_crumb_and_cookie() {
  local username=$1
  local password=$2
  local cookie_jar=$3

  local full_crumb=$(curl -u "$username:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
  local arr_crumb=(${full_crumb//:/ })
  local only_crumb=$(echo ${arr_crumb[1]})

  echo "$only_crumb"
}

# Function to make a POST request
make_post_request() {
  local username=$1
  local password=$2
  local cookie_jar=$3
  local crumb=$4
  local data=$5
  local url_post=$6

  curl -s -X POST -u "$username:$password" $url/$url_post \
    -H "Connection: keep-alive" \
    -H "Accept: application/json, text/javascript" \
    -H "X-Requested-With: XMLHttpRequest" \
    -H "$crumb" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --cookie $cookie_jar \
    --data-raw "$data" 
}

# Check if environment variables are set
if [ -z "$JENKINS_USER_ID" ] || [ -z "$JENKINS_PASSWORD" ] || [ -z "$JENKINS_FULL_NAME" ] || [ -z "$JENKINS_EMAIL" ]; then
  echo "Error: Environment variables are not set." >&2
  exit 1
fi

# Encode variables using Python
username=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input(), safe=''))" <<< "$JENKINS_USER_ID")
new_password=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input(), safe=''))" <<< "$JENKINS_PASSWORD")
fullname=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input(), safe=''))" <<< "$JENKINS_FULL_NAME")
email=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input(), safe=''))" <<< "$JENKINS_EMAIL")
url_urlEncoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote(input(), safe=''))" <<< "$url")

# Get the crumb and cookie
cookie_jar="$(mktemp)"
only_crumb=$(get_crumb_and_cookie "admin" "$password" "$cookie_jar")

# Confirm the URL
data="rootUrl=$url_urlEncoded%2F&Jenkins-Crumb=$only_crumb&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22rootUrl%22%3A%20%22$url_urlEncoded%2F%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D"
make_post_request "admin" "$password" "$cookie_jar" "$only_crumb" "$data" "/setupWizard/configureInstance"

# Make the request to create an admin user
data="username=$username&password1=$new_password&password2=$new_password&fullname=$fullname&email=$email&Jenkins-Crumb=$only_crumb&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D"
make_post_request "admin" "$password" "$cookie_jar" "$only_crumb" "$data" "securityRealm/createAccountByAdmin"

# Create User API Token
only_crumb=$(get_crumb_and_cookie "$username" "$new_password" "$cookie_jar")
data="newTokenName=api-token&Jenkins-Crumb=$only_crumb&json=%7B%22newTokenName%22%3A%22api-token%22%2C%22Jenkins-Crumb%22%3A%22$only_crumb%22%7D&core%3Aapply=&Submit=Generate"
result=$(make_post_request "$username" "$new_password" "$cookie_jar" "$only_crumb" "$data" "user/$username/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken")

# Check if the token was created
if [ $? -eq 0 ]; then
  echo "Token created successfully"
  echo "Token: $(echo $result | jq -r '.data.tokenValue')"

  export JENKINS_API_TOKEN=$(echo $result | jq -r '.data.tokenValue')

  wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar -q --show-progress --progress=bar:force:noscroll
  PLUGIN_LIST_FILE=/var/jenkins_home/plugins.txt

  # Install plugins with the Jenkins CLI
  for plugin in $(cat $PLUGIN_LIST_FILE)
  do
    echo "Installing $plugin"
    java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin $plugin
    check_status
  done

  echo "Restarting Jenkins"
  java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart
  
else
  echo "Token creation failed"
  exit 1
fi

# Clean up
rm -f $cookie_jar
rm -f jenkins-cli.jar

echo "Jenkins setup complete"

