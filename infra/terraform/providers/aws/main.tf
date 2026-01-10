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

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# Web Server EC2 Instance
resource "aws_instance" "web" {
  ami                    = local.windows_ami_id
  instance_type          = var.web_instance_type
  vpc_security_group_ids = [data.aws_security_group.default.id]
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
    Role = "web-server"
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
  ami                    = local.windows_ami_id
  instance_type          = var.sql_instance_type
  vpc_security_group_ids = [data.aws_security_group.default.id]
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
    Role = "sql-server"
  })

  get_password_data = false
}

# MinIO Server EC2 Instance
resource "aws_instance" "minio" {
  ami                    = local.windows_ami_id
  instance_type          = var.minio_instance_type
  vpc_security_group_ids = [data.aws_security_group.default.id]
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
    Role = "minio-server"
  })

  get_password_data = false
}
