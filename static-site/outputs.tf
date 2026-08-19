output "resource_id" {
  value = aws_cloudfront_distribution.this.id
}

output "endpoint" {
  description = "The CDN hostname the site is served from."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "port" {
  value = 443
}

output "bucket" {
  description = "Where the built assets are uploaded. The deployment step that follows writes here."
  value       = aws_s3_bucket.this.bucket
}
