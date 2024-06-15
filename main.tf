# 
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
     region = var.region
}

data "aws_availability_zone" "availabilityzone" {
  name = "eu-central-1a"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    tags = {
        name = "main"
    } 
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch=true
  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "nsg" {
    vpc_id = aws_vpc.main.id
    name = "EC2securitygroup"
    description = "Allow inbound and outbound rule"
  inbound {
    from_port   = 0
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.local_ip
  }
  inbound {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  inbound {
    from_port   = 0
    to_port     = 8172
    protocol    = "tcp"
    cidr_blocks = var.local_ip
  }
 
}

resource "aws_ec2_instance" "UXCEW10PRApp01" {
    name = var.ec2name
    ami = var.ami
    instance_type = var.instance_type
    security_groups = aws_security_group.nsg.id
    subnet_id = aws_subnet.subnet.id
    user_data = <<-EOF
    #!/bin/bash
    
    # Update package repositories
    apt-get update -y
    
    # Install nginx
    apt-get install nginx -y
    
    # Start nginx service
    systemctl start nginx
    
    # Enable nginx to start on boot
    systemctl enable nginx
  EOF
}



