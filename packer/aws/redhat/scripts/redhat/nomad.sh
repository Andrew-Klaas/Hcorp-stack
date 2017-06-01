#!/bin/bash

set -exv


NOMAD_VERSION=0.5.6

INSTANCE_PRIVATE_IP=$(/usr/sbin/ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')

#######################################
# NOMAD INSTALL
#######################################

# install dependencies
echo "Installing dependencies..."
sudo yum install -y wget build-essential curl git-core mercurial bzr libpcre3-dev pkg-config zip default-jre qemu libc6-dev-i386 silversearcher-ag jq htop vim unzip liblxc1 lxc-dev docker.io 
sudo yum install -y yum-utils 
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce

sudo yum install -y java-1.8.0-openjdk
## Download and unpack spark

sudo wget -P /ops/examples/nomad/spark https://s3.amazonaws.com/rcgenova-nomad-spark/spark-2.1.0-bin-nomad-preview-6.tgz
sudo tar -xvf /ops/examples/nomad/spark/spark-2.1.0-bin-nomad-preview-6.tgz --directory /ops/examples/nomad/spark
sudo mv /ops/examples/nomad/spark/spark-2.1.0-bin-nomad-preview-6 /ops/examples/nomad/spark/spark
sudo rm /ops/examples/nomad/spark/spark-2.1.0-bin-nomad-preview-6.tgz

# install nomad
echo "Fetching nomad..."
cd /tmp/

wget -q https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -O nomad.zip

echo "Installing nomad..."
unzip nomad.zip
rm nomad.zip
sudo chmod +x nomad
sudo mv nomad /usr/bin/nomad
sudo mkdir -pm 0600 /etc/nomad.d

# setup nomad directories
sudo mkdir -pm 0600 /opt/nomad
sudo mkdir -p /opt/nomad/data

echo "Nomad installation complete."

# MOVE THIS TO PACKER
sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=nomad agent
Requires=network-online.target
After=network-online.target
[Service]
EnvironmentFile=-/etc/sysconfig/nomad
Restart=on-failure
ExecStart=/usr/bin/nomad agent $NOMAD_FLAGS -config=/etc/systemd/system/nomad.d/
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/nomad.service