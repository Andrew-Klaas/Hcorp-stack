#!/usr/bin/env bash
set -e
set -x 
set -v


curl -X PUT -d '{"Datacenter": "dc1", "Node": "rds", "Address": "'$1'","Service": {"Service": "db", "Port": 3306}}' \
    http://127.0.0.1:8500/v1/catalog/register