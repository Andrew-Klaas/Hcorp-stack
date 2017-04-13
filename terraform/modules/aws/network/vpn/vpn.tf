variable "name" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "customer_gateway_ip" {}
variable "env_name" {}
variable "tunnel_address" { default = [] }

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = "${var.vpc_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = " ${var.env_name}"
  }
}

resource "aws_customer_gateway" "customer_gateway" {
  bgp_asn    = 65000
  ip_address = "${var.customer_gateway_ip}"
  type       = "ipsec.1"

  tags {
    Name = "${var.env_name}CG"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gateway.id}"
  customer_gateway_id = "${aws_customer_gateway.customer_gateway.id}"
  type                = "ipsec.1"

  tags {
    Name = "${var.env_name}VPN"
  }

  lifecycle {
    prevent_destroy = true
  }
}

#resource "aws_vpn_connection_route" "office" {
#    destination_cidr_block = "192.168.10.0/24"
#    vpn_connection_id = "${aws_vpn_connection.main.id}"
#}

