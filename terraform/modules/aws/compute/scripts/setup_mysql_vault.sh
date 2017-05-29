#!/bin/bash

#step 1:
if [ -z "$1" ]; then
	echo "No arg/endpoint specified!"
	exit
fi
if vault status | grep active > /dev/null; then
	sudo yum install -y mysql
	export ROOT_TOKEN=$(consul kv get service/vault/root-token)
	export NOMAD_TOKEN=$(consul kv get service/vault/nomad-token)
	vault auth $ROOT_TOKEN
	vault write mysql/config/connection connection_url="$2:$3@tcp($1:3306)/"
	vault write mysql/roles/app sql="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL PRIVILEGES ON app.* TO '{{name}}'@'%';"
	vault read mysql/creds/app
	echo "mysql ip:"  
	echo $MYSQL_IP
	echo "nomad-token"
	echo $NOMAD_TOKEN
	mysql -h $1 -u $2 -p$3 -e 'create database app;'
fi

# Launch fabio and app
# curl -H "Host: app.com" http://127.0.0.1:9999/
# while true; do curl -H "Host: app.com" http://127.0.0.1:9999/; sleep 1; done