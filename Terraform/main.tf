# Ayrton DevOps main.tf

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "ayrton_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

# Subnet
resource "aws_subnet" "ayrton_subnet" {
  vpc_id                  = aws_vpc.ayrton_vpc.id
  cidr_block              = var.subnet_cidr_block
  map_public_ip_on_launch = true
  tags = {
    Name = var.subnet_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ayrton_igw" {
  vpc_id = aws_vpc.ayrton_vpc.id
  tags = {
    Name = var.igw_name
  }
}

# Route Table
resource "aws_route_table" "ayrton_rtb" {
  vpc_id = aws_vpc.ayrton_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ayrton_igw.id
  }
  tags = {
    Name = var.rtb_name
  }
}

# Route Table Association
resource "aws_route_table_association" "ayrton_rtba" {
  subnet_id      = aws_subnet.ayrton_subnet.id
  route_table_id = aws_route_table.ayrton_rtb.id
}

# Security Group
resource "aws_security_group" "ayrton_sg" {
  vpc_id = aws_vpc.ayrton_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name
  }
}

# EC2 Instance
resource "aws_instance" "ayrton_web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.ayrton_subnet.id
  security_groups = [
    aws_security_group.ayrton_sg.name
  ]
  tags = {
    Name = var.instance_name
  }
}

# Load Balancer
resource "aws_lb" "ayrton_alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ayrton_sg.id]
  subnets            = [aws_subnet.ayrton_subnet.id]
  tags = {
    Name = var.alb_name
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "ayrton_alb_lis" {
  load_balancer_arn = aws_lb.ayrton_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, World"
      status_code  = "200"
    }
  }
}

# RDS Instance
resource "aws_db_instance" "ayrton_rds" {
  allocated_storage      = var.rds_allocated_storage
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_instance_class
  username               = var.rds_username
  password               = var.rds_password
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.ayrton_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.ayrton_rds_sub.name
  skip_final_snapshot    = true
}

# RDS Subnet Group
resource "aws_db_subnet_group" "ayrton_rds_sub" {
  name       = var.rds_subnet_group_name
  subnet_ids = [aws_subnet.ayrton_subnet.id]
  tags = {
    Name = var.rds_subnet_group_name
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "ayrton_cf" {
  origin {
    domain_name = aws_lb.ayrton_alb.dns_name
    origin_id   = "lb-origin"
  }

  default_cache_behavior {
    target_origin_id       = "lb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = var.cf_restricted_locations
    }
  }

  tags = {
    Name = var.cf_name
  }
}

resource "aws_instance" "monitoring_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.ayrton_subnet.id
  security_groups = [
    aws_security_group.ayrton_sg.name
  ]
  tags = {
    Name = "monitoring-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -aG docker ec2-user
              sudo curl -L "https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              EOF
}

resource "null_resource" "docker_setup" {
  depends_on = [aws_instance.monitoring_instance]

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ec2-user/docker-compose",
      "echo '${file("./monitoring/docker-compose.yml")}' > /home/ec2-user/docker-compose/docker-compose.yml",
      "cd /home/ec2-user/docker-compose",
      "docker-compose up -d"
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.monitoring_instance.public_ip
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa") # Path to your SSH key
    }
  }
}
