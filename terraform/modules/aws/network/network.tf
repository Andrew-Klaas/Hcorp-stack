#--------------------------------------------------------------
# This module creates all networking resources
#--------------------------------------------------------------

variable "name" {}
variable "vpc_cidr" {}
variable "azs" { default = [] }
variable "environment" {default = "dev"}
variable "customer_gateway_ip" {  }
variable "env_name" { default = "dev" }
variable "private_subnets" { default = [] }
variable "private_subnet_names" { default = [] }
variable "tunnel_address" { default = [] }
variable "public_subnets" { default = [] }
variable "public_subnet_names" { default = [] }

module "vpc" {
  source = "./vpc"

  name        = "${var.name}-vpc"
  env_name    = "${var.env_name}"
  cidr        = "${var.vpc_cidr}"
  environment = "${var.environment}"
}

module "private_subnet" {
  source = "./private_subnet"

  private_subnet_names = "${var.private_subnet_names}"
  private_subnets      = "${var.private_subnets}"
  vpc_id               = "${module.vpc.vpc_id}"
  azs                  = "${var.azs}"
}

module "public_subnet" {
  source = "./public_subnet"

  public_subnet_names = "${var.public_subnet_names}"
  public_subnets      = "${var.public_subnets}"
  vpc_id              = "${module.vpc.vpc_id}"
  azs                 = "${var.azs}"
}

#module "vpn" {
#  source = "./vpn"
#  name                = "${var.env_name}"
#  vpc_cidr            = "${var.vpc_cidr}"
#  vpc_id              = "${module.vpc.vpc_id}"
#  customer_gateway_ip = "${var.customer_gateway_ip}"
#  env_name            = "${var.env_name}"
#  tunnel_address      = "${var.tunnel_address}"
#}

## VPC
output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_cidr" {
  value = "${module.vpc.vpc_cidr}"
}

output "private_subnet_ids" { 
  value = "${module.private_subnet.subnet_ids}" 
}

output "public_subnet_ids" { 
  value = "${module.public_subnet.subnet_ids}" 
}


