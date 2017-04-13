#!/bin/bash
set -e
set -x
set -v


sudo yum install -y mysql

sleep 60s

echo "starting vault install"

export VAULT_ADDR=http://127.0.0.1:8200

cget() { curl -sf "http://127.0.0.1:8500/v1/kv/service/vault/$1?raw"; }

if [ ! $(cget root-token) ]; then

  sudo echo "test2" > /tmp/test2
  echo "Initialize Vault"
  vault init -address=http://localhost:8200 | tee /tmp/vault.init > /dev/null

  # Store master keys in consul for operator to retrieve and remove
  COUNTER=1
  cat /tmp/vault.init | grep 'Key' | awk '{print $4}' | for key in $(cat -); do
    curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/unseal-key-$COUNTER -d $key
    COUNTER=$((COUNTER + 1))
  done

  export ROOT_TOKEN=$(cat /tmp/vault.init | grep 'Root' | awk '{print $4}')
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/root-token -d $ROOT_TOKEN

  echo "Remove master keys from disk"
  #shred /tmp/vault.init

  #echo "Setup Vault demo"
  #curl -fX PUT 127.0.0.1:8500/v1/kv/service/nodejs/show_vault -d "true"
  #curl -fX PUT 127.0.0.1:8500/v1/kv/service/nodejs/vault_files -d "aws.html,generic.html"
else
  echo "Vault has already been initialized, skipping." > /tmp/test
fi

sleep 10s

sudo echo "test3" > /tmp/test3

echo "Unsealing Vault"
vault unseal $(cget unseal-key-1)
vault unseal $(cget unseal-key-2)
vault unseal $(cget unseal-key-3)

sleep 10s

echo "Vault setup complete."

instructions() {
  cat <<EOF
We use an instance of HashiCorp Vault for secrets management.
It has been automatically initialized and unsealed once. Future unsealing must
be done manually.
The unseal keys and root token have been temporarily stored in Consul K/V.
  /service/vault/root-token
  /service/vault/unseal-key-{1..5}
Please securely distribute and record these secrets and remove them from Consul.
EOF
  exit 0
}

sleep 10s

#Create Nomad Vault Token for mysql
export ROOT_TOKEN=$(consul kv get service/vault/root-token)
vault auth $ROOT_TOKEN

#vault audit-enable file file_path=/var/log/vault_audit.log

if [ ! $(cget nomad-token) ]; then
  sudo echo "test4" > /tmp/test4
  vault mount mysql
  vault policy-write nomad-server ~/policy/nomad-server-policy.hcl
  export NOMAD_TOKEN=$(vault token-create -policy nomad-server | grep 'token ' | awk '{print $2}')
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/nomad-token -d $NOMAD_TOKEN
fi

#instructions


