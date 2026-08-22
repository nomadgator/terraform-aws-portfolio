# Terraform AWS Static Website

## Overview

A simple static website hosted on Amazon S3 and provisioned entirely using Terraform.

This project demonstrates Infrastructure as Code (IaC) fundamentals by creating and configuring an S3 static website without manually configuring the infrastructure through the AWS Management Console.

## Architecture

Internet
    │
    ▼
Amazon S3
    │
    └── index.html

Terraform manages:

- S3 bucket
- Static website configuration
- Public access configuration
- Bucket policy
- S3 versioning
- Server-side encryption
- Website object deployment

## AWS Services

- Amazon S3
- AWS IAM policy
- Terraform AWS Provider

## Terraform Concepts Demonstrated

- Terraform provider configuration
- Resource dependencies
- Terraform outputs
- Data sources
- Infrastructure as Code
- Terraform state
- Provider version locking
- `terraform plan`
- `terraform apply`
- `terraform destroy`

## Security

The bucket uses a restricted public-access configuration that allows anonymous users to retrieve website objects while preventing public ACL-based access.

S3 server-side encryption using AES-256 is enabled for stored objects.

S3 versioning is also enabled to protect against accidental object overwrites.

## Project Structure

```text
01-aws-static-website/
├── .terraform.lock.hcl
├── main.tf
├── outputs.tf
├── versions.tf
├── README.md
└── website/
    └── index.html