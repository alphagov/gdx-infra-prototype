resource "aws_security_group" "jump_security_group" {
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

data "aws_iam_policy_document" "jump_iam_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "jump_iam_role" {
  name = "gdx-jump-iam-role"

  managed_policy_arns   = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  assume_role_policy    = data.aws_iam_policy_document.jump_iam_policy_document.json
}
