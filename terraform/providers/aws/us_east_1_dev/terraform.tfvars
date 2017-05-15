#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

name = "akproject"
env_name = "AKdevaws"
domain = "AKdevaws.ak.com"
vpc_cidr = "10.103.0.0/20"
region = "us-east-1"
environment = "DEV"
customer_gateway_ip = "167.115.8.25"

private_subnets = ["10.103.0.0/22", "10.103.4.0/22"]
private_subnet_names = ["AKdevaws-A", "AKdevaws-B"]

public_subnets = ["10.103.8.0/22"]
public_subnet_names = ["AKdevaws-C"]

azs = ["us-east-1a", "us-east-1b"]

#tunnel_address = [""]

key_path = "~/.ssh/id_rsa"
private_key = "${file("~/.ssh/id_rsa")}"

db_name           = "AkApp"
db_engine         = "mysql"
db_engine_version = "5.6.27"
db_port           = "3306"
db_az                      = "us-east-1b"
db_multi_az                = "false"
db_instance_type           = "db.t2.micro"
db_storage_gbs             = "100"
db_iops                    = "1000"
db_storage_type            = "gp2"
db_apply_immediately       = "true"
db_publicly_accessible     = "false"
db_storage_encrypted       = "false"
db_maintenance_window      = "mon:04:03-mon:04:33"
db_backup_retention_period = "7"
db_backup_window           = "10:19-10:49"


