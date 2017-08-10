#!/bin/bash

set -x


NOMAD_VERSION=0.6.0

INSTANCE_PRIVATE_IP=$(/usr/sbin/ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')

#######################################
# NOMAD INSTALL
#######################################

# install dependencies
echo "Installing dependencies..."
sudo yum install -y wget build-essential curl git-core mercurial bzr libpcre3-dev pkg-config zip default-jre qemu libc6-dev-i386 silversearcher-ag jq htop vim unzip liblxc1 lxc-dev docker.io 
sudo yum install -y yum-utils 

YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

logger "Running"

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

if [[ ! -z ${YUM} ]]; then
  echo "Installing Docker with RHEL Workaround"
  sudo yum -y install ftp://fr2.rpmfind.net/linux/centos/7.3.1611/extras/x86_64/Packages/container-selinux-2.12-2.gite7096ce.el7.noarch.rpm
  curl -sSL https://get.docker.com/ | sed -e '365s/redhat/centos/' | sed -e '376s/redhat/centos/' | sudo sh
elif [[ ! -z ${APT_GET} ]]; then
  echo "Installing Docker"
  curl -sSL https://get.docker.com/ | sudo sh
else
  logger "Prerequisites not installed due to OS detection failure"
  exit 1;
fi

sudo sh -c "echo \"DOCKER_OPTS='--dns 127.0.0.1 --dns 8.8.8.8 --dns-search service.consul'\" >> /etc/default/docker"

logger "Complete"

sudo yum install -y java-1.8.0-openjdk
## Download and unpack spark

sudo wget -P /ops/examples/spark https://s3.amazonaws.com/nomad-spark/spark-2.1.0-bin-nomad.tgz
sudo tar -xvf /ops/examples/spark/spark-2.1.0-bin-nomad.tgz --directory /ops/examples/spark
sudo mv /ops/examples/spark/spark-2.1.0-bin-nomad /usr/local/bin/spark
sudo chown -R root:root /usr/local/bin/spark

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