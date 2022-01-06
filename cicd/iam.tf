resource "aws_iam_policy" "developers" {
  name        = "gdx-developers"
  path        = "/"
  description = "Policy for GDX Developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}