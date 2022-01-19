resource "aws_security_group" "jump_security_group" {
  name        = "gdx-jump-${var.stack_identifier}-security-group"
  description = "Jump Box for developer interactions via console with kafka"
  vpc_id      = aws_vpc.gdx_prototype.id
}

resource "aws_security_group_rule" "jump_allow_all_egress" {
  security_group_id = aws_security_group.jump_security_group.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
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

data "aws_iam_policy_document" "ecr_registry_readonly" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = ["ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage"]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/gdx-registry/*"]
  }
}

resource "aws_iam_policy" "gdx_registry_readonly" {
  name = "gdx-registry-readonly"
  policy = data.aws_iam_policy_document.ecr_registry_readonly.json
}

data "aws_s3_bucket" "gdx_artifact_storage" {
  bucket = "${data.aws_caller_identity.current.account_id}-gdx-artifacts"
}

data "aws_iam_policy_document" "package_store_readonly" {
  statement {
    sid = "ListBucket"

    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${data.aws_s3_bucket.gdx_artifact_storage.arn}"
    ]
  }
  statement {
    sid = "ReadObjects"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${data.aws_s3_bucket.gdx_artifact_storage.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "package_store_policy" {
  name   = "gdx-jump-${var.stack_identifier}-package-store-policy"
  policy = data.aws_iam_policy_document.package_store_readonly.json
}

resource "aws_iam_role" "jump_iam_role" {
  name = "gdx-jump-${var.stack_identifier}-iam-role"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    aws_iam_policy.package_store_policy.arn,
    aws_iam_policy.gdx_registry_readonly.arn]
  assume_role_policy  = data.aws_iam_policy_document.jump_iam_policy_document.json
}

resource "aws_iam_instance_profile" "gdx_jump_iam_profile" {
  name = "gdx-jump-${var.stack_identifier}-iam-profile"
  role = aws_iam_role.jump_iam_role.name
}

data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_instance" "jump_ec2_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.jump_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.gdx_jump_iam_profile.name
  user_data = templatefile(
    "jump_init.sh.tftpl",
    {
      bucket = "${data.aws_caller_identity.current.account_id}-gdx-artifacts"
    }
  )
}

