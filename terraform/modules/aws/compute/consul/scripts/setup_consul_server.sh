#!/usr/bin/env bash
set -e
set -v
set -x

# Read from the file we created
SERVER_COUNT=$(cat /tmp/consul-server-count | tr -d '\n')
CONSUL_JOIN=$(cat /tmp/consul-server-addr | tr -d '\n')
INSTANCE_PRIVATE_IP=$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')


# Write the flags to a temporary file
# enable UI for first node in cluster
if [ "${CONSUL_JOIN}" == "$(hostname -f)" ]; then

# Setup Consul UI on primary Consul server
sudo bash -c "cat >/etc/default/consul" << EOF
CONSUL_FLAGS="\
-server \
-bootstrap-expect=${SERVER_COUNT} \
-join=${CONSUL_JOIN} \
-data-dir=/opt/consul/data \
-client 0.0.0.0 -ui \
-advertise=${INSTANCE_PRIVATE_IP}"
EOF

# setup consul UI specific iptables rules
sudo iptables -I INPUT -s 0/0 -p tcp --dport 8500 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables.rules

else

sudo bash -c "cat >/etc/default/consul" << EOF
CONSUL_FLAGS="\
-server \
-bootstrap-expect=${SERVER_COUNT} \
-join=${CONSUL_JOIN} \
-advertise=${INSTANCE_PRIVATE_IP} \
-data-dir=/opt/consul/data"
EOF
fi

sudo bash -c "cat >/etc/systemd/system/consul.d/consul.json" << EOF
{
        "acl_enforce_version_8": false,
        "segments": [
          {"name": "alpha", "bind": "${INSTANCE_PRIVATE_IP}", "advertise": "${INSTANCE_PRIVATE_IP}", "port": 8303},
          {"name": "beta", "bind": "${INSTANCE_PRIVATE_IP}", "advertise": "${INSTANCE_PRIVATE_IP}", "port": 8304}
  ]
}
EOF

sudo chown root:root /etc/default/consul
sudo chmod 0644 /etc/default/consul

sudo echo 'nameserver 127.0.0.1' | sudo cat - /etc/resolv.conf > temp && sudo mv temp /etc/resolv.conf
#sudo echo 'nameserver 127.0.0.1' | sudo cat /etc/resolv.conf - > temp && sudo mv temp /etc/resolv.conf
sudo service dnsmasq restart
