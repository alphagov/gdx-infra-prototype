resource "aws_security_group" "jump_security_group" {
  name           = "gdx-jump-${var.stack_identifier}-security-group"
  description    = "Jump Box for developer interactions via console with kafka"
  vpc_id         = aws_vpc.gdx_prototype.id
}

resource "aws_security_group_rule" "jump_allow_all_egress" {
  security_group_id    = aws_security_group.jump_security_group.id
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
  name = "gdx-jump-${var.stack_identifier}-iam-role"

  managed_policy_arns   = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  assume_role_policy    = data.aws_iam_policy_document.jump_iam_policy_document.json
}

resource "aws_iam_instance_profile" "gdx_jump_iam_profile" {
  name = "gdx-jump-${var.stack_identifier}-iam-profile"
  role = aws_iam_role.jump_iam_role.name
}

data "aws_ami" "amazon_linux" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_instance" "jump_ec2_instance" {
  ami                     =  data.aws_ami.amazon_linux.id
  instance_type           = "t3.small"
  subnet_id               = aws_subnet.private[0].id
  vpc_security_group_ids  = [aws_security_group.jump_security_group.id]
  iam_instance_profile    = aws_iam_instance_profile.gdx_jump_iam_profile.name
}
