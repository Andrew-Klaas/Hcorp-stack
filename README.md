Playground for learning hashicorp tools.
Spins up: 3 Consul Servers, 3 Nomad Servers, 3 Nomad Clients, 1 Vault Server, and a MySQL database

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


# Set up
This repo will setup a full functionaing nomad cluster, consul cluster, vault instance, and mysql database

0. Get in the proper directory
	
	$ cd Hcorp-stack/terraform/providers/aws/us_east_1_dev/

1. setup a secrets.tfvars with the following vars (You need to create this file, with these vars)
	
	user = "andrewklaas"
	aws_access_key=""
	aws_secret_key=""
	db_username="your_user"
	db_password="your_password"

2. Launch Terraform
    
    $ terraform plan -var-file=secrets.tfvar   
	$ terraform apply -var-file=secrets.tfvars 
	
Your outputs should looklike this
	
	consul_ui = http://ec2-54-175-39-232.compute-1.amazonaws.com:8500/ui/
	db_endpoint = akproject-mysql.caaqf9qz0wbw.us-east-1.rds.amazonaws.com:3306
	nomad_client_addresses = [
    	ssh://ec2-52-201-213-3.compute-1.amazonaws.com,
    	ssh://ec2-54-204-246-72.compute-1.amazonaws.com,
    	ssh://ec2-107-23-28-45.compute-1.amazonaws.com
	]
	nomad_server_addresses = [
   	    ssh://ec2-52-91-246-211.compute-1.amazonaws.com,
    	ssh://ec2-54-173-62-139.compute-1.amazonaws.com,
    	ssh://ec2-54-89-163-87.compute-1.amazonaws.com
	]
	primary_vault = ssh://ec2-34-224-57-107.compute-1.amazonaws.com  

3. SSH into primary_vault, and then setup vault and mysql
	# use the url of the database and this pre-created script to configure vault for creating dynamic 
	# usernames and password, you will need to pass the db_endpoint and your db_username and db_password
	
	[andrewklaas@ip-10-103-9-162 tmp]$ /tmp/setup_mysql_vault.sh akproject-mysql.caaqf9qz0wbw.us-east-1.rds.amazonaws.com akuser akpassword

   the output should look like this (write down your mysql IP)
   	Success! Data written to: mysql/roles/app
	Key            	Value
	---            	-----
	lease_id       	mysql/creds/app/a04f7ca3-d31e-a894-09ed-902462cb3715
	lease_duration 	768h0m0s
	lease_renewable	true
	password       	ee62ebfe-1fc4-2eef-6027-ad7cdd7ec5e1
	username       	app-root-90a214e

	mysql ip:
	10.103.2.220
	nomad-token

4. create the "app" database in the mysql rds instance
	
	$ mysql -h  $db_ip -u akuser -p
    $ MySQL [(none)]> create database app;


5. now SSH into the first nomad server above from step 2. Make sure the cluster is running correctly
	
	[andrewklaas@ip-10-103-9-106 ~]$ nomad node-status
	ID        DC   Name                           Class   Drain  Status
	ec278d79  dc1  ip-10-103-11-161.ec2.internal  <none>  false  ready
	ec2c0a02  dc1  ip-10-103-10-8.ec2.internal    <none>  false  ready
	ec2dad26  dc1  ip-10-103-11-17.ec2.internal   <none>  false  ready
	[andrewklaas@ip-10-103-9-106 ~]$ nomad server-members
	Name                                 Address       Port  Status  Leader  Protocol  Build     Datacenter  Region
	ip-10-103-8-136.ec2.internal.global  10.103.8.136  4648  alive   false   2         0.5.5rc1  dc1         global
	ip-10-103-8-166.ec2.internal.global  10.103.8.166  4648  alive   true    2         0.5.5rc1  dc1         global
	ip-10-103-9-106.ec2.internal.global  10.103.9.106  4648  alive   false   2         0.5.5rc1  dc1         global

6. Now lets start some jobs, lets run redis (docker)
	
	$ cd jobs/
	$ nomad run redis.nomad
    $ nomad status redis
    make sure its running, there should be 3 redis tasks.

7. Check out the consul ui, Open the url from step to for "consul_ui" in your browser, you should see the "cache-redis" service registered along with consul/nomad/vault

8. run the fabio load balancer (go binary -> exec driver)
   
   $ nomad run fabio.nomad

Now check the fabio UI -> open want of the nomad CLIENT IP addresses in your browser with port 9998
ec2-52-201-213-3.compute-1.amazonaws.com:9998, you should see routes to redis if you ran that job

9. Now lets see some vault dynamic secrets. edit application.nomad and change

	# Change this to your database endoints IP address
	APP_DB_HOST = "10.103.2.115:3306"

	# Next run the job
	$ nomad run application.nomad
	#This pulls down a go boinary from aws S3 bucket and runs with the exec driver

10. Check Consul UI and Fabio UI to see that the app started running

11. Check the nomad jobs logs to see the app pulling dynamic usernames and password

	$ nomad status fabio
	$ nomad logs -stderr $fabio_allocation_id


# Nomad usage
Login to one of the nomad servers (see your terraform output).

	cd jobs
	nomad server-members
	nomad node-status
	nomad run fabio.nomad
	nomad run application.nomad

#Misc info:
For demo purposes, only destroy the nomad resources in terraform, then you dont have all the manual database setups

	$ terraform destroy -target=module.compute.module.nomad.aws_instance.nomad-server -var-file=secrets.tfvars
	$ terraform destroy -target=module.compute.module.nomad.aws_instance.nomad-client -var-file=secrets.tfvars

