 #!/bin/bash
set -v
set -x

echo "hi0" > /tmp/test0

sleep 60s

echo "hi1" > /tmp/test

username=${USER}

echo "hi2" > /tmp/test

echo "starting vault install"

export VAULT_ADDR=http://127.0.0.1:8200

# PKI specific variables
RootCAName="vault-ca-root"
IntermCAName="vault-ca-intermediate"
mkdir -p /tmp/certs/

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

sudo echo "test3" > /tmp/test3

echo "Unsealing Vault"
vault unseal $(cget unseal-key-1)
vault unseal $(cget unseal-key-2)
vault unseal $(cget unseal-key-3)

sudo echo "test4" > /tmp/test4

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

policy_setup() {
  logger "$0 - Configuring Vault Policies"
  # create policy named 'waycoolapp'
  echo "
  path \"${IntermCAName}/issue*\" {
    capabilities = [\"create\",\"update\"]
  }
  path \"secret/waycoolapp*\" {
    capabilities = [\"read\"]
  }
  path \"auth/token/renew\" {
    capabilities = [\"update\"]
  }
  path \"auth/token/renew-self\" {
    capabilities = [\"update\"]
  }
  " | vault policy-write waycoolapp -

  # create policy named 'admin-waycoolapp'
  echo '
  path "sys/mounts" {
    capabilities = ["list","read"]
  }
  path "secret/*" {
    capabilities = ["list", "read"]
  }
  path "secret/waycoolapp*" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }
  path "secret/aklaas" {
    capabilities = ["create", "read", "update", "delete", "list"]
  }
  path "supersecret/*" {
    capabilities = ["list", "read"]
  }' | vault policy-write admin-waycoolapp -
}

admin_setup() {
  logger "$0 - Configuring UserPass backend"
  # setup userpass for a personal login
  vault auth-enable userpass
  # create my credentials
  vault write auth/userpass/users/aklaas password=test policies="admin-waycoolapp"

  #Use this to show that user can't see other secets
  vault mount -path=supersecret generic
  vault write supersecret/admin admin_user=root admin_password=P@55w3rd

  vault mount -path=verysecret generic
  vault write verysecret/sensitive key=value password=35616164316lasfdasfasdfasdfasdfasf
}

pki_setup() {

  # Mount Root CA and generate cert
  vault unmount ${RootCAName} &> /dev/null || true

  vault mount -path ${RootCAName} pki
  vault mount-tune -max-lease-ttl=87600h ${RootCAName}
  vault write -format=json ${RootCAName}/root/generate/internal \
  common_name="${RootCAName}" ttl=87600h | tee >(jq -r .data.certificate > /tmp/certs/ca.pem) >(jq -r .data.issuing_ca > /tmp/certs/issuing_ca.pem) >(jq -r .data.private_key > /tmp/certs/ca-key.pem)

  # Mount Intermediate and set cert
  vault unmount ${IntermCAName} &> /dev/null || true
  vault mount -path ${IntermCAName} pki
  vault mount-tune -max-lease-ttl=87600h ${IntermCAName}
  vault write -format=json ${IntermCAName}/intermediate/generate/internal common_name="${IntermCAName}" ttl=43800h | tee >(jq -r .data.csr > /tmp/certs/${IntermCAName}.csr) >(jq -r .data.private_key > /tmp/certs/${IntermCAName}.pem)

  # Sign the intermediate certificate and set it
  vault write -format=json ${RootCAName}/root/sign-intermediate csr=@/tmp/certs/${IntermCAName}.csr common_name="${IntermCAName}" ttl=43800h | tee >(jq -r .data.certificate > /tmp/certs/${IntermCAName}.pem) >(jq -r .data.issuing_ca > /tmp/certs/${IntermCAName}_issuing_ca.pem)
  vault write ${IntermCAName}/intermediate/set-signed certificate=@/tmp/certs/${IntermCAName}.pem

  # Generate the roles
  vault write ${IntermCAName}/roles/example-dot-com allow_any_name=true max_ttl="1000h" generate_lease=true
  #auth as root first
  #vault write vault-ca-intermediate/issue/example-dot-com common_name=blah.example.com
}

approle_setup() {
  logger "$0 - Configuring AppRole"

  # enable approle backend
  vault auth-enable approle
  # create approle for 'waycoolapp' with above policy and approle specific parameters
  vault write auth/approle/role/waycoolapp secret_id_num_uses=1000 period=3600 policies=waycoolapp
  # read role_id for our approle
  vault read auth/approle/role/waycoolapp/role-id | grep role_id | awk '{print $2}' > /tmp/role_id
  # retrieve secret_id for our approle, and subsequently upload to consul for retrieval
  # DEMO PURPOSES ONLY - NOT RECOMMENDED
  vault write -format=json -f auth/approle/role/waycoolapp/secret-id | tee \
  >(jq --raw-output '.data.secret_id' > /tmp/secret_id) \
  >(jq --raw-output '.data.secret_id_accessor' > /tmp/secret_id_accessor)
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/role_id -d $(cat /tmp/role_id)
  sleep 2
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/secret_id -d $(cat /tmp/secret_id)
  sleep 2
  curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/secret_id_accessor -d $(cat /tmp/secret_id_accessor)
}

totp_setup()  {
  username=${USER}
  vault mount totp
  sudo tee /home/${username}/setup-totp-gen.sh > /dev/null <<EOF
    vault write totp/keys/test \
    generate=true \
    issuer=Vault \
    account_name=aklaas@aklaas.com
EOF

  sudo chown "${username}:${username}" "/home/${username}/setup-totp-gen.sh"
  sudo chmod +x "/home/${username}/setup-totp-gen.sh"
}

sudo echo "test-blah" /tmp/test-blah
if vault status | grep active > /dev/null; then
  # auth with root token
  #Create Nomad Vault Token for mysql
  export ROOT_TOKEN=$(consul kv get service/vault/root-token)
  vault auth $ROOT_TOKEN
  #vault audit-enable file file_path=/var/log/vault_audit.log
  if [ ! $(cget nomad-token) ]; then
    sudo echo "test5" > /tmp/test5
    vault mount mysql
    vault policy-write nomad-server /home/andrewklaas/policy/nomad-server-policy.hcl
    export NOMAD_TOKEN=$(vault token-create -policy nomad-server | grep 'token ' | awk '{print $2}')
    curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/nomad-token -d $NOMAD_TOKEN
    sudo echo $NOMAD_TOKEN > /tmp/test5
  fi

  vault write secret/waycoolapp User1SSN="200-23-9930" User2SSN="000-00-0002" ttl=60s

  policy_setup
  admin_setup
  pki_setup
  #totp_setup

fi
sudo echo "test6" > /tmp/test6
#instructions
