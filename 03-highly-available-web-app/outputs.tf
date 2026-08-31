# -----------------------------
# Application Load Balancer URL
# -----------------------------

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.app.dns_name}"
}

# -----------------------------
# VPC ID
# -----------------------------

output "vpc_id" {
  description = "ID of the Project 3 VPC"
  value       = aws_vpc.main.id
}

# -----------------------------
# RDS Endpoint
# -----------------------------

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}