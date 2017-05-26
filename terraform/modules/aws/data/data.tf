variable "name" {}
variable "vpc_cidr" {}
variable "vpc_id" {}
variable "private_subnet_ids"  { }
variable "public_subnet_ids"   { }
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

module "rds_mysql" {
  source = "./rds"

  name           = "${var.name}-mysql"
  vpc_id         = "${var.vpc_id}"
  vpc_cidr       = "${var.vpc_cidr}"
  subnet_ids     = "${var.private_subnet_ids}"
  db_name        = "${var.db_name}"
  username       = "${var.db_username}"
  password       = "${var.db_password}"
  engine         = "${var.db_engine}"
  engine_version = "${var.db_engine_version}"
  port           = "${var.db_port}"

  az                      = "${var.db_az}"
  multi_az                = "${var.db_multi_az}"
  instance_type           = "${var.db_instance_type}"
  storage_gbs             = "${var.db_storage_gbs}"
  iops                    = "${var.db_iops}"
  storage_type            = "${var.db_storage_type}"
  apply_immediately       = "${var.db_apply_immediately}"
  publicly_accessible     = "${var.db_publicly_accessible}"
  storage_encrypted       = "${var.db_storage_encrypted}"
  maintenance_window      = "${var.db_maintenance_window}"
  backup_retention_period = "${var.db_backup_retention_period}"
  backup_window           = "${var.db_backup_window}"
}

output "db_endpoint" { value = "${module.rds_mysql.endpoint}" }
output "db_username" { value = "${module.rds_mysql.username}" }
output "db_password" { value = "${module.rds_mysql.password}" }
output "db_address" { value = "${module.rds_mysql.address}"}

