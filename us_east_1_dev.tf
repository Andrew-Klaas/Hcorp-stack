variable "name" {}
variable "region" {}
variable "environment" {}
variable "vpc_cidr" {}
variable "azs" { default = [] }
variable "domain" {}
variable "env_name" {}

variable "private_subnets" { default = [] }
variable "private_subnet_names" { default = [] }
variable "tunnel_address" { default = [] }
variable "customer_gateway_ip" {}

variable "public_subnets" { default = [] }
variable "public_subnet_names" { default = [] }


variable "user" {}
variable "key_path" {}
variable "private_key" {}

variable "consul_server_count" {  }
variable "vault_server_count"  {  }
variable "nomad_server_count"  {  }
variable "nomad_client_count"  {  }
variable "aws_access_key"      { }
variable "aws_secret_key"      { }

variable "db_name" {}
variable "db_username" {}
variable "db_password" {}
variable "db_engine" {}
variable "db_engine_version" {}
variable "db_port" {}

variable "db_az" {}
variable "db_multi_az" {}
variable "db_instance_type" {}
variable "db_storage_gbs" {}
variable "db_iops" {}
variable "db_storage_type" {}
variable "db_apply_immediately" {}
variable "db_publicly_accessible" {}
variable "db_storage_encrypted" {}
variable "db_maintenance_window" {}
variable "db_backup_retention_period" {}
variable "db_backup_window" {}



##########
# devaws #
##########

terraform {
  backend "atlas" {
    name = "aklaas/Hcorp-demo "
  }
}

provider "aws" {
  region = "${var.region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

#resource "aws_route53_zone" "devaws" {
#  name          = "${var.domain}."
#  vpc_id        = "${module.network.vpc_id}"
#  comment       = ""
#  force_destroy = "false"
#}

module "network" {
  source = "terraform/modules/aws/network"

  name                = "${var.name}"
  environment         = "${var.environment}"
  vpc_cidr            = "${var.vpc_cidr}"
  azs                 = "${var.azs}"
  customer_gateway_ip = "${var.customer_gateway_ip}"

  private_subnets      = "${var.private_subnets}"
  private_subnet_names = "${var.private_subnet_names}"
  env_name             = "${var.env_name}"
  tunnel_address       = "${var.tunnel_address}"

  public_subnets       = "${var.public_subnets}"
  public_subnet_names  = "${var.public_subnet_names}"

}

module "compute" {
  source = "terraform/modules/aws/compute"

  name               = "${var.name}"
  region             = "${var.region}"
  
  vpc_id             = "${module.network.vpc_id}"
  vpc_cidr           = "${var.vpc_cidr}"
  
  private_subnet_ids = "${module.network.private_subnet_ids}"
  public_subnet_ids  = "${module.network.public_subnet_ids}"

  user                = "${var.user}"
  key_path            = "${var.key_path}"
  private_key         = "${var.private_key}"
  consul_server_count = "${var.consul_server_count}"
  nomad_server_count  = 3 #"${var.nomad_server_count}"
  nomad_client_count  = 5 #"${var.nomad_client_count}"
  vault_server_count  = 1 #"${var.vault_server_count}"

  db_address = "${module.data.db_address}"
  db_user = "${var.db_username}"
  db_password = "${var.db_password}"

}

module "data" {
  source = "terraform/modules/aws/data"

  name               = "${var.name}"
  vpc_id             = "${module.network.vpc_id}"
  vpc_cidr           = "${var.vpc_cidr}"
  private_subnet_ids = "${module.network.private_subnet_ids}"
  public_subnet_ids  = "${module.network.public_subnet_ids}"

  db_name        = "${var.db_name}"
  db_username       = "${var.db_username}"
  db_password       = "${var.db_password}"
  db_engine         = "${var.db_engine}"
  db_engine_version = "${var.db_engine_version}"
  db_port           = "${var.db_port}"

  db_az                      = "${var.db_az}"
  db_multi_az                = "${var.db_multi_az}"
  db_instance_type           = "${var.db_instance_type}"
  db_storage_gbs             = "${var.db_storage_gbs}"
  db_iops                    = "${var.db_iops}"
  db_storage_type            = "${var.db_storage_type}"
  db_apply_immediately       = "${var.db_apply_immediately}"
  db_publicly_accessible     = "${var.db_publicly_accessible}"
  db_storage_encrypted       = "${var.db_storage_encrypted}"
  db_maintenance_window      = "${var.db_maintenance_window}"
  db_backup_retention_period = "${var.db_backup_retention_period}"
  db_backup_window           = "${var.db_backup_window}"
}

output "consul_ui" {
  value = "${module.compute.consul_ui}"
}

output "nomad_server_addresses" {
  value = "${module.compute.nomad_server_addresses}"
}

output "nomad_client_addresses" {
  value = "${module.compute.nomad_client_addresses}"
}

output "primary_vault" {
  value = "${module.compute.primary_vault}"
}

output "vault_server_addresses" {
  value = "${module.compute.vault_server_addresses}"
}

output "db_endpoint" { 
  value = "${module.data.db_endpoint}" 
}
output "db_address" { 
  value = "${module.data.db_address}" 
}
