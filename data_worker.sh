#!/bin/bash
CYAN='\033[0;36m'
NC='\033[0m'

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq
apt-get install -y mysql-client

# Appends new hostname to /etc/hosts file. VM name is modified on creation with the prefix append.
if [[ $( cat /etc/hosts | grep -i "127.0.0.1 `hostname`") ]];
then
    echo -e "$CYAN[HOSTNAME EXISTS IN /etc/hosts]$NC"
else
    echo -e "$CYAN[HOSTNAME NOT FOUND, APPENDING HOSTNAME TO /etc/hosts]$NC"
    sudo sed -i "2i 127.0.0.1 `hostname`" /etc/hosts  
fi

curl -s https://s3.amazonaws.com/get.divvycloud.com/prod.html | bash

sed -i 's|DIVVY_DB_HOST=mysql|DIVVY_DB_HOST='${dbhost}'|g' /divvycloud/prod.env
sed -i 's|DIVVY_DB_USERNAME=divvy|DIVVY_DB_USERNAME='${dbuser}'|g' /divvycloud/prod.env
sed -i 's|DIVVY_DB_PASSWORD=divvy|DIVVY_DB_PASSWORD='${dbpasswd}'|g' /divvycloud/prod.env
sed -i 's|DIVVY_SECRET_DB_HOST=mysql|DIVVY_SECRET_DB_HOST='${dbhost}'|g' /divvycloud/prod.env
sed -i 's|DIVVY_SECRET_DB_USERNAME=divvy|DIVVY_SECRET_DB_USERNAME='${dbuser}'|g' /divvycloud/prod.env
sed -i 's|DIVVY_SECRET_DB_PASSWORD=divvy|DIVVY_SECRET_DB_PASSWORD='${dbpasswd}'|g' /divvycloud/prod.env
sed -i 's|DIVVY_REDIS_HOST=redis|DIVVY_REDIS_HOST='${redishost}'|g' /divvycloud/prod.env
#sed -i '/DIVVY_REDIS_HOST/a "DIVVY_REDIS_PASSWORD=XXXXXXXXXXXX"' /divvycloud/prod.env
#sed -i 's|#http_proxy=http://proxy.acmecorp.com|http_proxy=|g' /divvycloud/prod.env 
#sed -i 's|#https_proxy=http://proxy.acmecorp.com|https_proxy=|g' /divvycloud/prod.env 
#sed -i 's|#no_proxy=mysql,redis,169.254.169.254|no_proxy=mysql,redis,169.254.169.254|g' /divvycloud/prod.env

sed -i '3,36d' /divvycloud/docker-compose.yml
sed -i 's/divvycloud:latest/divvycloud:'${divvycloud_version}'/g'
sed -i 's|scale: 8|scale: '${worker_count}'|g' /divvycloud/docker-compose.yml
/usr/local/bin/docker-compose -f /divvycloud/docker-compose.yml up -d
cat<<EOF > /etc/cron.weekly/remove-docker-images
#!/bin/sh
docker image prune -f
EOF
chmod 755 /etc/cron.weekly/remove-docker-images
