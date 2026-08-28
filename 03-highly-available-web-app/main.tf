terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# -----------------------------
# VPC
# -----------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-3-vpc"
  }
}
# -----------------------------
# Public Subnets
# -----------------------------

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "project-3-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "project-3-public-b"
  }
}

# -----------------------------
# Private Subnets
# -----------------------------

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "project-3-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "project-3-private-b"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project-3-igw"
  }
}

# -----------------------------
# Public Route Table
# -----------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "project-3-public-rt"
  }
}

# -----------------------------
# Public Route Table Associations
# -----------------------------

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------
# NAT Gateway Elastic IP
# -----------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "project-3-nat-eip"
  }
}

# -----------------------------
# NAT Gateway
# -----------------------------

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "project-3-nat"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

# -----------------------------
# Private Route Table
# -----------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "project-3-private-rt"
  }
}

# -----------------------------
# Private Route Table Associations
# -----------------------------

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
# ALB Security Group
# -----------------------------

resource "aws_security_group" "alb" {
  name        = "project-3-alb-sg"
  description = "Allow HTTP traffic to the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-3-alb-sg"
  }
}

# -----------------------------
# EC2 Security Group
# -----------------------------

resource "aws_security_group" "ec2" {
  name        = "project-3-ec2-sg"
  description = "Allow application traffic from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-3-ec2-sg"
  }
}

# -----------------------------
# RDS Security Group
# -----------------------------

resource "aws_security_group" "rds" {
  name        = "project-3-rds-sg"
  description = "Allow PostgreSQL traffic from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-3-rds-sg"
  }
}

# -----------------------------
# Amazon Linux 2023 AMI
# -----------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------
# EC2 Instance A
# -----------------------------

resource "aws_instance" "app_a" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_a.id

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl enable httpd
              systemctl start httpd

              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Terraform Project 3</title>
              </head>
              <body>
                <h1>Terraform Project 3</h1>
                <h2>Application Server A</h2>
                <p>Availability Zone: ap-southeast-1a</p>
                <p>Infrastructure managed with Terraform.</p>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "project-3-app-a"
  }
}

# -----------------------------
# EC2 Instance B
# -----------------------------

resource "aws_instance" "app_b" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_b.id

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl enable httpd
              systemctl start httpd

              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Terraform Project 3</title>
              </head>
              <body>
                <h1>Terraform Project 3</h1>
                <h2>Application Server B</h2>
                <p>Availability Zone: ap-southeast-1b</p>
                <p>Infrastructure managed with Terraform.</p>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "project-3-app-b"
  }
}

# -----------------------------
# Application Load Balancer
# Target Group
# -----------------------------

resource "aws_lb_target_group" "app" {
  name     = "project-3-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "project-3-app-tg"
  }
}

# -----------------------------
# Target Group Attachments
# -----------------------------

resource "aws_lb_target_group_attachment" "app_a" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_b" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_b.id
  port             = 80
}

# -----------------------------
# Application Load Balancer
# -----------------------------

resource "aws_lb" "app" {
  name               = "project-3-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "project-3-alb"
  }
}

# -----------------------------
# ALB Listener
# -----------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# -----------------------------
# RDS DB Subnet Group
# -----------------------------

resource "aws_db_subnet_group" "main" {
  name = "project-3-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "project-3-db-subnet-group"
  }
}

# -----------------------------
# RDS PostgreSQL
# -----------------------------

resource "aws_db_instance" "postgres" {
  identifier = "project-3-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"

  db_name  = "project3db"
  username = "project3admin"
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false
  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 0

  tags = {
    Name = "project-3-postgres"
  }
}








