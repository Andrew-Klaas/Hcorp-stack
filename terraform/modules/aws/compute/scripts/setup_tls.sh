#!/bin/bash
set -x

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

if [[ ! -z ${YUM} ]]; then
  echo "Setting up $1 certificates - type EL - Derivatives"
  MV=$(lsb_release -rs | cut -f1 -d.)
  if [[ $MV == 6 ]]; then
    URL="https://dl.fedoraproject.org/pub/epel/6/x86_64/easy-rsa-2.2.2-1.el6.noarch.rpm"
  elif [[ $MV == 7 ]]; then
    URL="https://dl.fedoraproject.org/pub/epel/7/x86_64/e/easy-rsa-2.2.2-1.el7.noarch.rpm"
  fi
  /usr/bin/sudo rpm -Uvh ${URL}
  EASYRSAPATH="/usr/share/easy-rsa/2.0"
elif [[ ! -z ${APT_GET} ]]; then
  echo "Setting up $1 certificates - type Debian/Ubuntu - Derivatives"
  apt-get install easy-rsa
  EASYRSAPATH="/usr/share/easy-rsa"
else
  echo "OS Detection failed, certificates not created."
  exit 1;
fi

#Expect a product name as first argument
if [ -z "$1" ]; then
  echo "First argument should be a product name, like consul, vault or nomad"
  exit 1;
fi

cd ${EASYRSAPATH}/
source ./vars
${EASYRSAPATH}/clean-all
${EASYRSAPATH}/build-ca --batch
${EASYRSAPATH}/build-dh --batch
${EASYRSAPATH}/build-key-server --batch $(hostname)
mkdir -p /etc/ssl/$1
cp ${EASYRSAPATH}/keys/ca.crt /etc/ssl/$1
cp ${EASYRSAPATH}/keys/$(hostname).crt /etc/ssl/$1/$1.crt
cp ${EASYRSAPATH}/keys/$(hostname).key /etc/ssl/$1/$1.key

chown -R $1:$1 /etc/ssl/$1
cp /etc/ssl/$1/ca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust