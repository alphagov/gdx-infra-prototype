locals {
  az_names       = data.aws_availability_zones.available.names
  current_region = data.aws_region.current.name
  vpc_cidr       = "10.0.0.0/16"
}


resource "aws_vpc" "gdx_prototype" {
  cidr_block = local.vpc_cidr
  tags = {
    Name = "gdx-prototype-${var.stack_identifier}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

resource "aws_subnet" "private" {
  count             = length(local.az_names)
  vpc_id            = aws_vpc.gdx_prototype.id
  availability_zone = local.az_names[count.index]
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index)
  tags = {
    Name = "gdx-prototype-${var.stack_identifier}-private-${count.index}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.gdx_prototype.id
  tags = {
    Name = "gdx-prototype-${var.stack_identifier}-private"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
