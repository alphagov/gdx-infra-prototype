resource "aws_s3_bucket" "gdx_artifact_storage" {
  bucket = "${data.aws_caller_identity.current.account_id}-gdx-artifacts"
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "stack_state_block" {
  bucket = aws_s3_bucket.gdx_artifact_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
