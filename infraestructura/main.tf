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

# =====================================================================
# 1. GENERACIÓN AUTOMÁTICA DE CLAVES SSH (.PEM)
# =====================================================================

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

# =====================================================================
# 2. CONFIGURACIÓN DE RED (VPC, SUBREDES Y GATEWAYS)
# =====================================================================

resource "aws_vpc" "vpc_principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-curso" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id
  tags   = { Name = "igw-curso" }
}

# IP Elástica dedicada exclusivamente para el NAT Gateway
resource "aws_eip" "eip_nat" {
  domain = "vpc"
  tags   = { Name = "eip-nat-gateway" }
}

# NAT Gateway colocado en la subred pública para dar salida a las privadas
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_nat.id
  subnet_id     = aws_subnet.subred_web.id
  tags          = { Name = "nat-gateway-curso" }

  depends_on = [aws_internet_gateway.igw]
}

# Subredes
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

resource "aws_subnet" "subred_datos" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "subred-privada-datos" }
}

# =====================================================================
# 3. TABLAS DE RUTEO (PÚBLICA Y PRIVADA)
# =====================================================================

# Tabla Pública (Hacia Internet Gateway)
resource "aws_route_table" "rt_publica" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rt-publica" }
}

resource "aws_route_table_association" "web_assoc" {
  subnet_id      = aws_subnet.subred_web.id
  route_table_id = aws_route_table.rt_publica.id
}

# Tabla Privada (Hacia NAT Gateway)
resource "aws_route_table" "rt_privada" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "rt-privada" }
}

# Asociar subredes privadas a la tabla del NAT Gateway
resource "aws_route_table_association" "app_assoc" {
  subnet_id      = aws_subnet.subred_app.id
  route_table_id = aws_route_table.rt_privada.id
}

resource "aws_route_table_association" "datos_assoc" {
  subnet_id      = aws_subnet.subred_datos.id
  route_table_id = aws_route_table.rt_privada.id
}

# =====================================================================
# 4. GRUPOS DE SEGURIDAD (SECURITY GROUPS)
# =====================================================================

resource "aws_security_group" "sg_web" {
  name        = "sg_capa_web"
  description = "Permite trafico web hacia las instancias ec2"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
  name        = "sg_capa_app"
  description = "Permite trafico desde la capa web"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.sg_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_datos" {
  name        = "sg_capa_datos"
  description = "Permite trafico de base de datos desde la capa app"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.sg_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================================================================
# 5. INSTANCIAS EC2 E IP ELÁSTICA WEB (CON SCRIPTS USER_DATA)
# =====================================================================

# Instancia Web (Pública)
resource "aws_instance" "ec2_web" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_web.id
  vpc_security_group_ids = [aws_security_group.sg_web.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-web" }

  user_data = <<-EOF
              #!/bin/bash
              # 1. Actualizar SO
              yum update -y
              yum upgrade -y
              # 2. Instalar Docker
              yum install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              # 3. Instalar Git
              yum install git -y
              # 4. Validar (Imprime logs en /var/log/user-data.log)
              docker --version
              git --version
              EOF
}

resource "aws_eip" "eip_web" {
  instance = aws_instance.ec2_web.id
  domain   = "vpc"
  tags     = { Name = "eip-ec2-web" }
}

# Instancia Aplicación (Privada)
resource "aws_instance" "ec2_app" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_app.id
  vpc_security_group_ids = [aws_security_group.sg_app.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-app" }

  user_data = <<-EOF
              #!/bin/bash
              # 1. Actualizar SO
              yum update -y
              yum upgrade -y
              # 2. Instalar Docker
              yum install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              # 3. Instalar Git
              yum install git -y
              # 4. Validar
              docker --version
              git --version
              EOF
}

# Instancia Datos (Privada)
resource "aws_instance" "ec2_datos" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_datos.id
  vpc_security_group_ids = [aws_security_group.sg_datos.id]
  key_name               = aws_key_pair.key_pair.key_name
  tags                   = { Name = "ec2-datos" }

  user_data = <<-EOF
              #!/bin/bash
              # 1. Actualizar SO
              yum update -y
              yum upgrade -y
              # 2. Instalar Docker
              yum install docker -y
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user
              # 3. Instalar Git
              yum install git -y
              # 4. Validar
              docker --version
              git --version
              # 5. Instalar Docker Compose
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
              EOF
}

# =====================================================================
# 6. ENTRADAS DE PANTALLA (OUTPUTS)
# =====================================================================

output "ip_publica_web" { value = aws_eip.eip_web.public_ip }
output "ip_privada_app" { value = aws_instance.ec2_app.private_ip }
output "ip_privada_datos" { value = aws_instance.ec2_datos.private_ip }
