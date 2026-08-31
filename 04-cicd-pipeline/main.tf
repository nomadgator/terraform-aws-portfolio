
# -----------------------------
# S3 Website Bucket
# -----------------------------

resource "aws_s3_bucket" "website" {
  bucket_prefix = "project-4-client-website-"
  force_destroy = true


  tags = {
    Name        = "project-4-client-website"
    Project     = "Terraform Portfolio Project 4"
    Environment = "production"
  }
}

# -----------------------------
# S3 Website Configuration
# -----------------------------

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# -----------------------------
# S3 Public Access Configuration
# -----------------------------

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# -----------------------------
# Public Read Bucket Policy
# -----------------------------

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  depends_on = [
    aws_s3_bucket_public_access_block.website
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# -----------------------------
# Website Files
# -----------------------------

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
}

# -----------------------------
# GitHub OIDC Provider
# -----------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name    = "github-actions-oidc"
    Project = "Terraform Portfolio Project 4"
  }
}

# -----------------------------
# CI/CD IAM Policy
# -----------------------------

resource "aws_iam_policy" "cicd_deploy" {
  name        = "project-4-cicd-deploy"
  description = "Allow CI/CD pipeline to deploy the website to the Project 4 S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.website.arn
      },
      {
        Sid    = "ManageWebsiteFiles"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  tags = {
    Name    = "project-4-cicd-deploy"
    Project = "Terraform Portfolio Project 4"
  }
}


# -----------------------------
# GitHub Actions IAM Role
# -----------------------------

resource "aws_iam_role" "github_actions" {
  name = "project-4-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:nomadgator/terraform-aws-portfolio:*"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "project-4-github-actions"
    Project = "Terraform Portfolio Project 4"
  }
}

# -----------------------------
# Attach CI/CD Policy to Role
# -----------------------------

resource "aws_iam_role_policy_attachment" "cicd_deploy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.cicd_deploy.arn
}

