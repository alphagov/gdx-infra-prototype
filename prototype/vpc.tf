resource "aws_vpc" "gdx_prototype" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "gdx-prototype-${var.stack_identifier}"
  }
}