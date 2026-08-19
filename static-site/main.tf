# A pre-built single-page app behind the shared CDN.

locals {
  slug   = replace(var.name, "/", "-")
  bucket = substr("${replace(var.environment, "/", "-")}-${local.slug}", 0, 63)

  sizing = {
    small  = { price_class = "PriceClass_100", default_ttl = 3600 }
    medium = { price_class = "PriceClass_200", default_ttl = 86400 }
    large  = { price_class = "PriceClass_All", default_ttl = 604800 }
  }
  size = local.sizing[var.size_class]

  tags = merge(var.tags, {
    "lembos.dev/component"   = var.name
    "lembos.dev/environment" = var.environment
    "lembos.dev/stamp"       = var.stamp
  })
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = local.bucket
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = var.index_document
  price_class         = local.size.price_class
  comment             = "Lembos ${var.name} (${var.environment})"

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = local.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = local.bucket
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    default_ttl = local.size.default_ttl
    max_ttl     = local.size.default_ttl * 2
    min_ttl     = 0

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # A single-page app routes client-side, so a deep link is a 404 at the origin and a 200 at the
  # entry point. Without this, every refresh on a sub-route is a broken page.
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/${var.index_document}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "cdn" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.this.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
        }
      }
    }]
  })
}
