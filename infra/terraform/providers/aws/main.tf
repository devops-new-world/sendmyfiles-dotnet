# AWS Provider Module for SendMyFiles

# Get Windows Server 2025 Base AMI (or fallback to 2022)
data "aws_ami" "windows_2025" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Fallback to Windows Server 2022 if 2025 not available
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use Windows Server 2025 if available, otherwise 2022
# Default to Windows Server 2025 Base AMI (ami-06777e7ef7441deff) if available
locals {
  # Try to use the specific AMI ID first, then try data source lookups
  # Default to Windows Server 2025 Base AMI (ami-06777e7ef7441deff) that user has access to
  # Try custom AMI first, then Windows 2025 lookup, then hardcoded fallback, then Windows 2022
  windows_ami_id = var.windows_ami_id != "" ? var.windows_ami_id : try(data.aws_ami.windows_2025.id, "ami-06777e7ef7441deff", data.aws_ami.windows_2022.id)
}

# Get SQL Server 2022 AMI (or use Windows 2025 with SQL installed separately)
data "aws_ami" "sql_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-SQL_2022*", "Windows_Server-2025-English-Full-SQL_2022*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Fallback: use Windows 2025 Base if SQL AMI not available (SQL will be installed via Ansible)
locals {
  sql_ami_id = var.sql_ami_id != "" ? var.sql_ami_id : try(data.aws_ami.sql_2022.id, local.windows_ami_id)
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "sendmyfiles-vpc-${var.random_suffix}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "sendmyfiles-igw-${var.random_suffix}"
  })
}

# Subnets
resource "aws_subnet" "web" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.web_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "web-subnet-${var.random_suffix}"
  })
}

resource "aws_subnet" "sql" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.sql_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = merge(var.tags, {
    Name = "sql-subnet-${var.random_suffix}"
  })
}

resource "aws_subnet" "minio" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.minio_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = merge(var.tags, {
    Name = "minio-subnet-${var.random_suffix}"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.tags, {
    Name = "public-rt-${var.random_suffix}"
  })
}

resource "aws_route_table_association" "web" {
  subnet_id      = aws_subnet.web.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "web" {
  name        = "web-sg-${var.random_suffix}"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags

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
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5985
    to_port     = 5985
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

resource "aws_security_group" "sql" {
  name        = "sql-sg-${var.random_suffix}"
  description = "Security group for SQL server"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
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

resource "aws_security_group" "minio" {
  name        = "minio-sg-${var.random_suffix}"
  description = "Security group for MinIO server"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    from_port       = 9001
    to_port         = 9001
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
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

# Web Server EC2 Instance
resource "aws_instance" "web" {
  ami                    = local.windows_ami_id
  instance_type          = var.web_instance_type
  subnet_id              = aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  iam_instance_profile   = var.instance_profile != "" ? var.instance_profile : null

  user_data = base64encode(<<-EOF
    <powershell>
    winrm quickconfig -q
    winrm set winrm/config/Service/Auth '@{Basic="true"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/Service '@{AllowUnencrypted="true"}'
    </powershell>
  EOF
  )

  root_block_device {
    volume_type = "gp3"
    volume_size = var.web_disk_size_gb
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "sendmyfiles-web-${var.random_suffix}"
  })

  get_password_data = false
}

# Elastic IP for Web Server
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"
  tags = merge(var.tags, {
    Name = "web-eip-${var.random_suffix}"
  })
}

# SQL Server EC2 Instance
resource "aws_instance" "sql" {
  ami                    = local.sql_ami_id
  instance_type          = var.sql_instance_type
  subnet_id              = aws_subnet.sql.id
  vpc_security_group_ids = [aws_security_group.sql.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  user_data = base64encode(<<-EOF
    <powershell>
    winrm quickconfig -q
    winrm set winrm/config/Service/Auth '@{Basic="true"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/Service '@{AllowUnencrypted="true"}'
    </powershell>
  EOF
  )

  root_block_device {
    volume_type = "gp3"
    volume_size = var.sql_disk_size_gb
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = var.sql_data_disk_size_gb
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "sendmyfiles-sql-${var.random_suffix}"
  })

  get_password_data = false
}

# MinIO Server EC2 Instance
resource "aws_instance" "minio" {
  ami                    = local.windows_ami_id
  instance_type          = var.minio_instance_type
  subnet_id              = aws_subnet.minio.id
  vpc_security_group_ids = [aws_security_group.minio.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  user_data = base64encode(<<-EOF
    <powershell>
    winrm quickconfig -q
    winrm set winrm/config/Service/Auth '@{Basic="true"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/Service '@{AllowUnencrypted="true"}'
    </powershell>
  EOF
  )

  root_block_device {
    volume_type = "gp3"
    volume_size = var.minio_disk_size_gb
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = var.minio_data_disk_size_gb
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "sendmyfiles-minio-${var.random_suffix}"
  })

  get_password_data = false
}

