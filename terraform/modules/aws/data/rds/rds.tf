variable "name" { }
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "subnet_ids" {}
variable "db_name" {}
variable "username" {}
variable "password" {}
variable "engine" {}
variable "engine_version" {}
variable "port" {}
variable "az" {}
variable "multi_az" {}
variable "instance_type" {}
variable "storage_gbs" {  }
variable "iops" {  }
variable "storage_type" {  }
variable "apply_immediately" {  }
variable "publicly_accessible" {  }
variable "storage_encrypted" {  }
variable "maintenance_window" {  }
variable "backup_retention_period" {  }
variable "backup_window" {  }

resource "aws_security_group" "rds" {
  name        = "${var.name}"
  vpc_id      = "${var.vpc_id}"
  description = "Security group for RDS"

  tags { Name = "${var.name}" }

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "${var.name}"
  subnet_ids  = ["${split(",", var.subnet_ids)}"]
  description = "Subnet group for RDS"
  tags {
     Name = "DB subnet group"
  }
}

resource "aws_db_instance" "master" {
  identifier     = "${var.name}"
  name           = "${var.db_name}"
  username       = "${var.username}"
  password       = "${var.password}"
  engine         = "${var.engine}"
  engine_version = "${var.engine_version}"
  port           = "${var.port}"

  # availability_zone       = "${var.az}"
  multi_az                = "${var.multi_az}"
  instance_class          = "${var.instance_type}"
  allocated_storage       = "${var.storage_gbs}"
  # iops                    = "${var.iops}"
  storage_type            = "${var.storage_type}"
  apply_immediately       = "${var.apply_immediately}"
  publicly_accessible     = "${var.publicly_accessible}"
  storage_encrypted       = "${var.storage_encrypted}"
  maintenance_window      = "${var.maintenance_window}"
  # backup_retention_period = "${var.backup_retention_period}"
  # backup_window           = "${var.backup_window}"

  # final_snapshot_identifier = "${var.name}"
  # snapshot_identifier     = "EXISTING_SNAPSHOT_ID"
  vpc_security_group_ids    = ["${aws_security_group.rds.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.default.id}"

  skip_final_snapshot       = true
}

output "endpoint" { value = "${aws_db_instance.master.endpoint}" }
output "username" { value = "${var.username}" }
output "password" { value = "${var.password}" }
