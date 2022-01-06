data "aws_caller_identity" "current" {}

# S3 bucket to hold the state of our terraform stacks
resource "aws_s3_bucket" "stack_state" {
  bucket = "${data.aws_caller_identity.current.account_id}-tfstate-${var.stack_identifier}"
  acl    = "private"

  # To allow us to roll back state
  versioning {
    enabled = true
  }

  # To clean up old state
  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 360
    }
  }
}

resource "aws_s3_bucket_public_access_block" "stack_state_block" {
  bucket = aws_s3_bucket.stack_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}
