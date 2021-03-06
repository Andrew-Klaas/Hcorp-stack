#!/bin/sh

set -x
set -v
set -e

sudo apt-get -y update
sudo apt-get install -y vim curl wget unzip 
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
sudo chmod +x ./jq
sudo cp jq /usr/bin

DNSLISTENADDR="127.0.0.1"

echo Installing Dnsmasq...

sudo apt-get -y update
sudo apt-get -y install dnsmasq

echo Configuring Dnsmasq...

sudo mkdir -p /etc/dnsmasq.d
sudo chmod 777 /etc/dnsmasq.d
cat > /etc/dnsmasq.d/10-consul <<'EOF'
server=/consul/127.0.0.1#8600
EOF
