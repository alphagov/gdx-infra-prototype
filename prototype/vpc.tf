locals {
  az_names       = data.aws_availability_zones.available.names
  current_region = data.aws_region.current.name
  vpc_cidr       = "10.0.0.0/16"
}


resource "aws_vpc" "gdx_prototype" {
  cidr_block = local.vpc_cidr

  enable_dns_support = true
  enable_dns_hostnames = true

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

resource "aws_security_group" "aws_endpoint_interfaces_security_group" {
  name           = "aws-endpoint-${var.stack_identifier}-security-group"
  description    = "Allow access to AWS endpoints (ssm, ec2 and messages)"
  vpc_id         = aws_vpc.gdx_prototype.id
}

resource "aws_security_group_rule" "endpoint_https_ingress" {
  security_group_id    = aws_security_group.aws_endpoint_interfaces_security_group.id
  from_port            = 443
  to_port              = 443
  protocol             = "tcp"
  cidr_blocks          = [aws_vpc.gdx_prototype.cidr_block]
  type                 = "ingress"
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id               = aws_vpc.gdx_prototype.id
  service_name         = "com.amazonaws.${local.current_region}.ssm"
  private_dns_enabled  = true
  tags                 = {
    Name = "gdx-prototype-${var.stack_identifier}-private-ssm"
  }
  vpc_endpoint_type    = "Interface"
  security_group_ids   = [
    aws_security_group.aws_endpoint_interfaces_security_group.id,
  ]
  subnet_ids           = aws_subnet.private[*].id
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id       = aws_vpc.gdx_prototype.id
  service_name = "com.amazonaws.${local.current_region}.ssmmessages"
  private_dns_enabled  = true
  tags = {
    Name = "gdx-prototype-${var.stack_identifier}-private-ssmmsg"
  }
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.aws_endpoint_interfaces_security_group.id,
  ]
  subnet_ids           = aws_subnet.private[*].id
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id       = aws_vpc.gdx_prototype.id
  service_name = "com.amazonaws.${local.current_region}.ec2messages"
  private_dns_enabled  = true
  tags = {
    Name = "gdx-prototype-${var.stack_identifier}-private-ec2msg"
  }
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.aws_endpoint_interfaces_security_group.id,
  ]
  subnet_ids           = aws_subnet.private[*].id
}
