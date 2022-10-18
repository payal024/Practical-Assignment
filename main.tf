# Provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.35.0"
    }
  }
}

provider "aws" {
  region  = var.region
}
# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Project = "pratical-assignment"
    Name = "Practical VPC"
 }
}
# Create Public Subnet1
resource "aws_subnet" "pub_sub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_sub1_cidr_block
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Project = "practical-assignment"
     Name = "public_subnet1"
 
 }
}


