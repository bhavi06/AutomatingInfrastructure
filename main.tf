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


#Resource to create SSH Key or Private Key
resource "tls_private_key" "demo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Resource to Create Key Pair & Download Locally on Linux
resource "aws_key_pair" "demo_key_pair" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.demo_key.public_key_openssh
  

}


#Resource to Download Key Pair on Windows
resource "local_file" "local_key_pair" {
  filename = "${var.key_pair_name}.pem"
  file_permission = "0400"
  content = tls_private_key.demo_key.private_key_pem
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
  ingress {
    from_port   = 0
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 8172
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
}

resource "aws_instance" "devserver" {
    ami = var.ami
    instance_type = var.instance_type
    subnet_id = aws_subnet.subnet.id
    vpc_security_group_ids = [aws_security_group.nsg.id]
    key_name = aws_key_pair.demo_key_pair.key_name


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



