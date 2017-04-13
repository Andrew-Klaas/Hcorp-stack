variable "name" { default = "public" }
variable "vpc_id" {}
variable "azs" { default = [] }
variable "public_subnets" { default = [] }
variable "public_subnet_names" { default = [] }



resource "aws_internet_gateway" "public" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_subnet" "public" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.public_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.public_subnets)}"

  tags {
    Name = "${element(var.public_subnet_names, count.index)}"
  }

  lifecycle {
    create_before_destroy = true
  }
  map_public_ip_on_launch = true
}

#resource "aws_route" "internet_access" {
#  route_table_id         = "${var.vpc_id.main_route_table_id}"
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = "${aws_internet_gateway.default.id}"
#}

resource "aws_route_table" "public" {
  vpc_id = "${var.vpc_id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.public.id}"
  }

  tags { Name = "${var.name}.${element(var.azs, count.index)}" }
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

output "subnet_ids" { value = "${join(",", aws_subnet.public.*.id)}" }
