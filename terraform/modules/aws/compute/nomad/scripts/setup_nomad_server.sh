#!/usr/bin/env bash
#######################################
# NOMAD CONFIGURATION
#######################################

sleep 20s

#INSTANCE_PRIVATE_IP=$(/sbin/ifconfig eth0 | grep "inet" | awk 'FNR == 1 {print $2}')
INSTANCE_PRIVATE_IP=$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')
INSTANCE_HOST_NAME=$(hostname)
nomad_server_nodes=3

#make sure Vault is done, need to pull auth token
#
# Note this is a hack, need to refactor, we should do a for loop and wait for the key to be put in consul
#
export VAULT_TOKEN=$(consul kv get service/vault/root-token)

sudo mkdir -p /etc/systemd/system/nomad.d/
sudo tee /etc/systemd/system/nomad.d/nomad.hcl > /dev/null <<EOF
name       = "${INSTANCE_HOST_NAME}"
data_dir   = "/opt/nomad/data"
log_level  = "DEBUG"
datacenter = "dc1"
bind_addr = "0.0.0.0"
server {
  enabled          = true
  bootstrap_expect = ${nomad_server_nodes}
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

sudo echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts
sudo service dnsmasq restart

#######################################
# START SERVICES
#######################################
sudo systemctl daemon-reload
sudo systemctl enable nomad.service
sudo systemctl start nomad


#sudo yum install -y java-1.8.0-openjdk
## Download and unpack spark

sudo wget -P /ops/examples/spark https://s3.amazonaws.com/nomad-spark/spark-2.1.0-bin-nomad.tgz
sudo tar -xvf /ops/examples/spark/spark-2.1.0-bin-nomad.tgz --directory /ops/examples/spark
sudo mv /ops/examples/spark/spark-2.1.0-bin-nomad /usr/local/bin/spark
sudo chown -R root:root /usr/local/bin/spark

sudo systemctl enable docker.service
sudo systemctl start docker

sleep 5s

DOCKER_BRIDGE_IP_ADDRESS=(`ifconfig docker0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`)
sudo echo "nameserver $DOCKER_BRIDGE_IP_ADDRESS" | sudo tee /etc/resolv.conf.new
sudo cat /etc/resolv.conf | sudo tee --append /etc/resolv.conf.new
sudo cp /etc/resolv.conf.new /etc/resolv.conf
sudo systemctl restart dnsmasq
