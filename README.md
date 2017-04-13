Playground for learning hashicorp tools.
Spins up: 3 Consul Servers, 3 Nomad Servers, 3 Nomad Clients, 1 Vault Server

all nodes have consul installed

# Terraform Use with AWS  (see Packer below)

## Requirements
Terraform installed  https://www.terraform.io/
Quick 101: https://www.terraform.io/intro/getting-started/install.html

## Docs related to credentials

Terraform notes on credentials
https://www.terraform.io/docs/providers/aws/index.html

    terraform plan -var-file=secrets.tfvars 


## Terraform usage

This repo is organized in a way to encourage code re-use. Terraform modules are basically reusable functions,
they are located at
    
    /terraform/modules

The other imporant main directory is the "provider" directory, where we actually define the VPC setups,

    /terraform/providers

# Packer Use with AWS 

## Requirements
Packer installed, https://www.packer.io/downloads.html

Quick 101: https://www.packer.io/intro/getting-started/install.html

## Docs related to credentials
https://www.packer.io/docs/builders/amazon.html#specifying-amazon-credentials

    packer build -var 'aws_access_key=YOURACCESSKEY' -var 'aws_secret_key=YOURSECRETKEY' packer.json

## Packer Usage
Use packer to provision images in AWS
    
    cd /packer/aws/redhat
    packer build -var 'aws_access_key=YOURACCESSKEY' -var 'aws_secret_key=YOURSECRETKEY' packer.json

configuration scripts are located at

    /packer/scripts/redhat


# Nomad usage
Login to one of the nomad servers (see your terraform output).

	cd jobs
	nomad server-members
	nomad node-status
	nomad run fabio.nomad
	nomad run application.nomad
From the output of terraform you can click on the consul UI to see your services.

# Mysql setup
take a look at 
	
	https://github.com/Andrew-Klaas/Hcorp-stack/blob/master/terraform/modules/aws/compute/scripts/setup_mysql_vault.sh
That won't work right out of the box, you will need to change the username and password depending on what you used in your secrets.tfvars file



