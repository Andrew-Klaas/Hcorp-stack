#!/usr/bin/env bash
#######################################
# NOMAD CONFIGURATION
#######################################

set -e
set -v
set -x
sleep 20s

INSTANCE_PRIVATE_IP=$(/sbin/ifconfig eth0 | grep "inet" | awk 'FNR == 1 {print $2}')
INSTANCE_HOST_NAME=$(hostname)
nomad_server_nodes=3

export VAULT_TOKEN=$(consul kv get service/vault/root-token)

sudo mkdir -p /etc/systemd/system/nomad.d/
sudo tee /etc/systemd/system/nomad.d/nomad.hcl > /dev/null <<EOF
name       = "${INSTANCE_HOST_NAME}"
data_dir   = "/opt/nomad/data"
log_level  = "DEBUG"
datacenter = "dc1"
bind_addr = "0.0.0.0"
client {
  enabled = true
}
addresses {
  rpc  = "${INSTANCE_PRIVATE_IP}"
  serf = "${INSTANCE_PRIVATE_IP}"
}
advertise {
  http = "${INSTANCE_PRIVATE_IP}:4646"
}
consul {
}
vault {
  enabled = true
  address = "http://vault.service.consul:8200"
  token = "$VAULT_TOKEN"
  tls_skip_verify = true
}
EOF

sudo echo 'nameserver 127.0.0.1' | sudo cat - /etc/resolv.conf > temp && sudo mv temp /etc/resolv.conf
#sudo echo 'nameserver 127.0.0.1' | sudo cat /etc/resolv.conf - > temp && sudo mv temp /etc/resolv.conf
sudo service dnsmasq restart

#######################################
# START SERVICES
#######################################
sudo systemctl daemon-reload
sudo systemctl enable nomad.service
sudo systemctl start nomad


sudo yum install -y java-1.8.0-openjdk


