# Ayrton DevOps variables.tf

variable "aws_region" {
  default = "ap-southeast-1"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  default = "ayrton-vpc"
}

variable "subnet_cidr_block" {
  default = "10.0.1.0/24"
}

variable "subnet_name" {
  default = "ayrton-subnet"
}

variable "igw_name" {
  default = "ayrton-igw"
}

variable "rtb_name" {
  default = "ayrton-rt"
}

variable "sg_name" {
  default = "ayrton-sg"
}

variable "ami_id" {
  default = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_name" {
  default = "ayrton-web-instance"
}

variable "alb_name" {
  default = "ayrton-alb"
}

variable "rds_allocated_storage" {
  default = 20
}

variable "rds_engine" {
  default = "mysql"
}

variable "rds_engine_version" {
  default = "8.0"
}

variable "rds_instance_class" {
  default = "db.t2.micro"
}

variable "rds_username" {
  default = "admin"
}

variable "rds_password" {
  default = "password"
}

variable "rds_subnet_group_name" {
  default = "main-db-subnet-group"
}

variable "cf_name" {
  default = "ayrton-cf"
}

variable "cf_restricted_locations" {
  default = ["JP", "HK"]
}


variable "monitoring_instance_name" {
  default = "monitoring-instance"
}

variable "secret_key" {}
