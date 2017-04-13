variable "name" {
  default = "private"
}

variable "vpc_id" {}

variable "azs" {
  default = []
}

variable "private_subnets" {
  default = []
}

variable "private_subnet_names" {
  default = []
}

resource "aws_subnet" "private" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.private_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.private_subnets)}"

  tags {
    Name = "${element(var.private_subnet_names, count.index)}"
  }

  lifecycle {
    create_before_destroy = true
  }
  map_public_ip_on_launch = false
}

output "subnet_ids" { value = "${join(",", aws_subnet.private.*.id)}" }