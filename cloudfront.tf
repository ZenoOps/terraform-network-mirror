resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "terraform-mirror-oac"
  description                       = "OAC for Terraform S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "mirror_cache" {
  name        = "mirror-cache-policy"
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "mirror_cache_binaries" {
  name        = "mirror-cache-binaries"
  default_ttl = 259200
  max_ttl     = 259200
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "mirror_origin_req" {
  name = "mirror-origin-request-policy"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

resource "aws_cloudfront_distribution" "mirror" {
  enabled = true
  comment = "Terraform Mirror Distribution"

  origin {
    domain_name = aws_s3_bucket.provider_cache.bucket_regional_domain_name
    origin_id   = "s3-terraform-mirror"

    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-terraform-mirror"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.mirror_cache_binaries.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.mirror_origin_req.id
  }

  ordered_cache_behavior {
    path_pattern     = "/registry.terraform.io/*.json"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-terraform-mirror"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.mirror_cache.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.mirror_origin_req.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "Terraform Mirror Distribution"
  }
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.mirror.domain_name
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.mirror.id
}