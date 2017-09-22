variable "user"                { }
variable "key_path"            { }
variable "private_key"         { }

variable "private_subnet_ids"  { }
variable "public_subnet_ids"   { }
variable "vpc_id"              { }

variable "consul_server_count" { }

variable "db_endpoint" { default = "" }

data "aws_ami" "redhat" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "name"
    values = ["aws-us-east-1-ubuntu-nomad*"]
  }
}

resource "aws_instance" "consul-server" {
    ami = "${data.aws_ami.redhat.id}"
    instance_type = "t2.micro"
    count = "${var.consul_server_count}"
    subnet_id = "${element(split(",", var.public_subnet_ids), 0)}"
    vpc_security_group_ids = ["${aws_security_group.sg.id}"]
    tags = {
      Name = "consul-server-${count.index}"
    }
    connection {
        user = "${var.user}"
        private_key = "${var.private_key}"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.consul_server_count} > /tmp/consul-server-count",
            "echo ${aws_instance.consul-server.0.private_dns} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/setup_consul_server.sh"
            #"${path.module}/scripts/register_db_consul.sh"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable consul.service",
            "sudo systemctl start consul"
        ]
    }
}

resource "aws_security_group" "sg" {
  name        = "consul-sg"
  description = "security group for consul"
  vpc_id      = "${var.vpc_id}"
  tags {
    Name = "consul-sg"
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
    to_port     = 8304
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

output "consul_server_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.consul-server.*.public_dns)}"
}

output "consul_ui" {
  value = "http://${aws_instance.consul-server.0.public_dns}:8500/ui/"
}

output "primary_consul" {
  value = "${aws_instance.consul-server.0.private_dns}"
}
