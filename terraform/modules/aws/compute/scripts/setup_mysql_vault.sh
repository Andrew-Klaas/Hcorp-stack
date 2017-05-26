#!/bin/bash
set -e

sudo yum install -y mysql

#step 1:
if [ -z "$1" ]; then
	echo "No arg/endpoint specified!"
    export MYSQL_IP=10.103.2.

else
	export MYSQL_IP=$(nslookup $1 | grep 'Address: ' | awk '{print $2}')
fi
export ROOT_TOKEN=$(consul kv get service/vault/root-token)
export NOMAD_TOKEN=$(consul kv get service/vault/nomad-token)
vault auth $ROOT_TOKEN
vault write mysql/config/connection connection_url="$2:$3@tcp($MYSQL_IP:3306)/"
vault write mysql/roles/app sql="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL PRIVILEGES ON app.* TO '{{name}}'@'%';"
vault read mysql/creds/app

echo "mysql ip:"  
echo $MYSQL_IP
echo "nomad-token"
echo $NOMAD_TOKEN

mysql -h $1 -u $2 -p '$3' dbname<<EOFMYSQL
create database app;
EOFMYSQL

# YOU HAVE TO DO THIS FIRST
#step 2:
#sudo yum install -y mysql
#mysql -h  10.103.0. -u akuser -p
#create database app

# Launch fabio and app
# curl -H "Host: app.com" http://127.0.0.1:9999/
# while true; do curl -H "Host: app.com" http://127.0.0.1:9999/; sleep 1; done