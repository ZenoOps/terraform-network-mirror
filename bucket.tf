resource "aws_s3_bucket" "provider_cache" {
  bucket = "provider-cache-tf-2"
  # force_destroy = true ///Allow the deletion of an S3 bucket even when it contains objects. Use with caution.
  tags = {
    Name = "provider-cache-tf-2"
  }
}

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