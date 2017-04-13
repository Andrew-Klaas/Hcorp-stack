variable "user" {}
variable "key_path" {}
variable "private_key" {}
variable "consul_server_count" {}
variable "nomad_server_count" {}
variable "nomad_client_count" {}


variable "private_subnet_ids" {}
variable "public_subnet_ids" {}
variable "vpc_id" {}
variable "primary_consul" { }
variable "primary_vault" { }

data "aws_ami" "redhat" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "name"
    values = ["aws-us-east-1-redhat-nomad*"]
  }
}

resource "aws_instance" "nomad-server" {
    ami = "${data.aws_ami.redhat.id}"
    instance_type = "t2.micro"
    count = "${var.nomad_server_count}"
    subnet_id = "${element(split(",", var.public_subnet_ids), 0)}"
    vpc_security_group_ids = ["${aws_security_group.sg.id}"]

    tags = {
      Name = "nomad-server-${count.index}"
    }
    connection {
        user = "${var.user}"
        private_key = "${file("~/.ssh/id_rsa")}"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.consul_server_count} > /tmp/consul-server-count",
            "echo ${var.primary_consul} > /tmp/consul-server-addr",
            "echo ${var.primary_vault}"
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
        scripts = [
            "${path.module}/../scripts/setup_nomad_server.sh"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable nomad.service",
            "sudo systemctl start nomad"
        ]
    }

    provisioner "file" {
      source      = "${path.module}/jobs"
      destination = "./"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable dnsmasq",
            "sudo systemctl start dnsmasq"
        ]
    }
}

resource "aws_instance" "nomad-client" {
    ami = "${data.aws_ami.redhat.id}"
    instance_type = "t2.micro"
    count = "${var.nomad_server_count}"
    subnet_id = "${element(split(",", var.public_subnet_ids), 0)}"
    vpc_security_group_ids = ["${aws_security_group.sg.id}"]

    tags = {
      Name = "nomad-client-${count.index}"
    }
    connection {
        user = "${var.user}"
        private_key = "${file("~/.ssh/id_rsa")}"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.consul_server_count} > /tmp/consul-server-count",
            "echo ${var.primary_consul} > /tmp/consul-server-addr",
            "echo ${var.primary_vault}"
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
        scripts = [
            "${path.module}/../scripts/setup_nomad_client.sh"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable nomad.service",
            "sudo systemctl start nomad"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl start docker"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable dnsmasq",
            "sudo systemctl start dnsmasq"
        ]
    }
}

resource "aws_security_group" "sg" {
  name        = "Nomad-sg"
  description = "security group for nomad"
  vpc_id      = "${var.vpc_id}"
  tags {
  	name = "nomad-sg"
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

    # HTTP access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
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

  #http = 4646
  #rpc  = 4647
  #serf = 4648
  # Nomad Communication
  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9998
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "nomad_server_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.nomad-server.*.public_dns)}"
}

output "nomad_client_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.nomad-client.*.public_dns)}"
}

#output "consul_ui" {
#  value = "http://${aws_instance.nomad-server.0.public_dns}:8500/ui/"
#}

#output "primary_consul" {
#  value = "${aws_instance.nomad-server.0.private_dns}"
#}