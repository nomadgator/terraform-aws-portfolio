# Project 4 — AWS CI/CD Pipeline

## Overview

This project demonstrates how to build an automated CI/CD pipeline for an AWS-hosted website using Terraform and GitHub Actions.

The goal is to allow website code stored in GitHub to be automatically deployed to an Amazon S3 website whenever changes are pushed to the repository.

Instead of manually uploading website files to AWS, GitHub Actions handles the deployment process.

## Architecture

```text
                  Developer
                      |
                      v
                 GitHub Repo
                      |
                 Git Push
                      |
                      v
             GitHub Actions
                      |
                OIDC Authentication
                      |
                      v
                 AWS IAM Role
                      |
                      v
                 Amazon S3
                      |
                      v
                  Website