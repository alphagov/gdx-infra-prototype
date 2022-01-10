resource "aws_security_group" "gdx_jump_security_group" {
  name           = "gdx-jump-security-group"
  description    = "Jump Box for developer interactions via console with kafka"
  vpc_id         = aws_vpc.gdx_prototype.id
}

resource "aws_security_group_rule" "jump_allow_all_egress" {
  security_group_id    = aws_security_group.gdx_security_group.id
  from_port            = 0 
  to_port              = 0
  protocol             = "-1"
  cidr_blocks          = ["0.0.0.0/0"]
  type                 = "egress"
}
