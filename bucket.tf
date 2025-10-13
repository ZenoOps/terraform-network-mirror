resource "aws_s3_bucket" "provider_cache" {
  bucket = "provider-cache-tf"
  force_destroy = true # We need this to run "terraform destroy" without prompting error "bucket is not empty" if the bucket has objects in it.
  tags = {
    Name = "provider-cache-tf"
  }
}

# Blocking all public access to the S3 bucket.
resource "aws_s3_bucket_public_access_block" "provider_cache_bucket" {
  bucket = aws_s3_bucket.provider_cache.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# This generates a policy document that allows CloudFront to access the S3 bucket locally.
data "aws_iam_policy_document" "allow_cloudfront" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.provider_cache.arn}/*"
    ]
    # This block only allows access if the request comes from the specified CloudFront distribution.
    condition {   
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.mirror.arn] 
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.provider_cache.id
  policy = data.aws_iam_policy_document.allow_cloudfront.json
}

# Uncomment the following block if you want to enable versioning on the S3 bucket.
# resource "aws_s3_bucket_versioning" "provider_cache" {
#   bucket = aws_s3_bucket.provider_cache.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }