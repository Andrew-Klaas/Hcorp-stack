
variable "name" {}
variable "region" {}
variable "vpc_cidr" {}
variable "vpc_id" {}
variable "user" {}
variable "key_path" {}
variable "private_key" {}

variable "consul_server_count" { }
variable "vault_server_count"  { }
variable "nomad_server_count"  { }
variable "nomad_client_count"  { }
variable "private_subnet_ids"  { }
variable "public_subnet_ids"   { }

variable "db_address"  { }
variable "db_user"     { }
variable "db_password" { }


module "vault" {
  source = "./vault"
  user = "${var.user}"
  key_path = "${var.key_path}"
  private_key = "${var.private_key}"
  private_subnet_ids = "${var.private_subnet_ids}"
  public_subnet_ids = "${var.public_subnet_ids}"
  vpc_id = "${var.vpc_id}"
  vault_server_count = "${var.vault_server_count}"
  consul_server_count = "${var.consul_server_count}"
  primary_consul = "${module.consul.primary_consul}" 

  db_address = "${var.db_address}"
  db_user    = "${var.db_user}"
  db_password = "${var.db_password}"

}

module "consul" {
  source = "./consul"
  user = "${var.user}"
  key_path = "${var.key_path}"
  private_key = "${var.private_key}"
  private_subnet_ids = "${var.private_subnet_ids}"
  public_subnet_ids = "${var.public_subnet_ids}"
  consul_server_count = "${var.consul_server_count}"
  vpc_id = "${var.vpc_id}"

}

module "nomad" {
  source = "./nomad"
  user = "${var.user}"
  key_path = "${var.key_path}"
  private_key = "${var.private_key}"
  private_subnet_ids = "${var.private_subnet_ids}"
  public_subnet_ids = "${var.public_subnet_ids}"
  consul_server_count = "${var.consul_server_count}"
  nomad_server_count = "${var.nomad_server_count}"
  nomad_client_count = "${var.nomad_client_count}"
  vpc_id = "${var.vpc_id}"
  primary_consul = "${module.consul.primary_consul}" 
  primary_vault  = "${module.vault.primary_vault}"

}

output "primary_consul" {
  value = "${module.consul.primary_consul}"
}

output "consul_server_addresses" {
  value = "${module.consul.consul_server_addresses}"
}

output "consul_ui" {
  value = "${module.consul.consul_ui}"
}

output "nomad_server_addresses" {
  value = "${module.nomad.nomad_server_addresses}"
}

output "nomad_client_addresses" {
  value = "${module.nomad.nomad_client_addresses}"
}

output "vault_ui" {
  value = "${module.vault.vault_ui}"
}

output "vault_server_addresses" {
  value = "${module.vault.vault_server_addresses}"
}

output "primary_vault" {
  value = "${module.vault.primary_vault}"
}
