variable "user"                { }
variable "key_path"            { }
variable "private_key"         { }

variable "private_subnet_ids"  { }
variable "public_subnet_ids"   { }
variable "vpc_id"              { }

variable "primary_consul"      { }
variable "consul_server_count" { }
variable "vault_server_count"  { }

data "aws_ami" "redhat" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "name"
    values = ["aws-us-east-1-redhat-vault*"]
  }
}

resource "aws_instance" "vault-server" {
    ami = "${data.aws_ami.redhat.id}"
    instance_type = "t2.micro"
    count = "${var.vault_server_count}"
    subnet_id = "${element(split(",", var.public_subnet_ids), 0)}"
    vpc_security_group_ids = ["${aws_security_group.sg.id}"]
    tags = {
      Name = "vault-server-${count.index}"
    }
    connection {
        user = "${var.user}"
        private_key = "${file("~/.ssh/id_rsa")}"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.consul_server_count} > /tmp/consul-server-count",
            "echo ${var.primary_consul} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/../scripts/setup_consul_client.sh"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable consul.service",
            "sudo systemctl start consul"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable vault.service",
            "sudo systemctl start vault"
        ]
    }

    # SETUP VAULT, NON PRODUCTION!
    provisioner "file" {
      source      = "${path.module}/policy"
      destination = "./"
    }

    provisioner "file" {
        source = "${path.module}/../scripts/setup_vault.sh",
        destination = "/tmp/setup_vault.sh"
    }

    provisioner "file" {
        source = "${path.module}/../scripts/setup_mysql_vault.sh",
        destination = "/tmp/setup_mysql_vault.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sleep 10s",
            "sudo chmod +x /tmp/setup_mysql_vault.sh",
            "sudo chmod +x /tmp/setup_vault.sh",
            "/tmp/setup_vault.sh &> /tmp/setup.log"
        ]
    }
}

resource "aws_security_group" "sg" {
  name        = "vault-sg"
  description = "security group for vault"
  vpc_id      = "${var.vpc_id}"
  tags {
    Name = "vault-sg"
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul communication
  ingress {
    from_port   = 8300
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault communication
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault stats
  ingress {
    from_port   = 8125
    to_port     = 8125
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul communication2
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere over 8500 for Consul UI
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "vault_client_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.vault-server.*.public_dns)}"
}

output "primary_vault" {
  value = "ssh://${aws_instance.vault-server.0.public_dns}"
}
