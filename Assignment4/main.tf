terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Subnets
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"
}

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"
}

# Security Groups
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "ec2_az1" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_az1.id
  security_groups = [aws_security_group.web.name]

  tags = {
    Name = var.instance1_name
  }
}

resource "aws_instance" "ec2_az2" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_az2.id
  security_groups = [aws_security_group.web.name]

  tags = {
    Name = var.instance2_name
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
}

# RDS Instance
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  name                 = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "admin"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds.id
  vpc_security_group_ids = [aws_security_group.rds.id]
}
