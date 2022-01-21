data "aws_iam_policy_document" "assume_codebuild" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_region" "current" {}

locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "codebuild_service" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/*"]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["arn:aws:ecr:${local.region}:${local.account_id}:repository/gdx/*"]
  }
}

resource "aws_iam_policy" "codebuild_service" {
  name   = "aws-codebuild-service"
  policy = data.aws_iam_policy_document.codebuild_service.json
}


resource "aws_iam_role" "codebuild" {
  name               = "codebuild-pipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_codebuild.json
  managed_policy_arns = [
    aws_iam_policy.codebuild_service.arn
  ]
}

resource "aws_codebuild_project" "demo_producer" {
  name         = "demo_producer"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    location = "https://github.com/alphagov/gdx-service-prototype"
    type     = "GITHUB"
    buildspec = templatefile(
      "demo_producer_buildspec.yml.tftpl",
      {
        ECR_URI       = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com",
        ECR_REPO_NAME = "gdx/demo-producer"
      }
    )
  }

}

#TODO: logs_config
#TODO: iam permissions
