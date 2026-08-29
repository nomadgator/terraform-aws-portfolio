# -----------------------------
# Project Outputs
# -----------------------------

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website.id
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role used by GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

