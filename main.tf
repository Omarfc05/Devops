terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. SEGURIDAD
resource "tls_private_key" "clave_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "clave-proyecto-academy"
  public_key = tls_private_key.clave_ssh.public_key_openssh
}

resource "local_file" "guardar_clave" {
  content         = tls_private_key.clave_ssh.private_key_pem
  filename        = "${path.module}/clave-academia.pem"
  file_permission = "0400"
}

# 2. RED
resource "aws_vpc" "vpc_principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-curso" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id
  tags   = { Name = "igw-curso" }
}

resource "aws_subnet" "subred_web" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "subred-publica-web" }
}

resource "aws_subnet" "subred_app" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "subred-privada-app" }
}

resource "aws_route_table" "rt_publica" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "web_assoc" {
  subnet_id      = aws_subnet.subred_web.id
  route_table_id = aws_route_table.rt_publica.id
}

# 3. GRUPOS DE SEGURIDAD
resource "aws_security_group" "sg_web" {
  name   = "sg_web"
  vpc_id = aws_vpc.vpc_principal.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "sg_app" {
  name   = "sg_app"
  vpc_id = aws_vpc.vpc_principal.id

  ingress {
    from_port       = 8080
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. INSTANCIAS
resource "aws_instance" "ec2_web" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_web.id
  vpc_security_group_ids = [aws_security_group.sg_web.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-web" }
  user_data              = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker git -y
              systemctl enable docker
              systemctl start docker
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              cd /home/ec2-user
              git clone https://github.com/Omarfc05/Devops.git
              cd Devops
              docker-compose up -d frontend
              EOF
}

resource "aws_instance" "ec2_app" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_app.id
  vpc_security_group_ids = [aws_security_group.sg_app.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-app" }
  user_data              = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker git -y
              systemctl enable docker
              systemctl start docker
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              cd /home/ec2-user
              git clone https://github.com/Omarfc05/Devops.git
              cd Devops
              docker-compose up -d backend-ventas backend-despachos
              EOF
}