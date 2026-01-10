variable "cloud_provider" {
  description = "Cloud provider to use (azure, aws, gcp)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be one of: azure, aws, gcp"
  }
}

variable "resource_group_name" {
  description = "Name of the resource group/resource group equivalent"
  type        = string
  default     = "sendmyfiles-rg"
}

variable "location" {
  description = "Cloud region for resources (provider-specific)"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "admin_username" {
  description = "Administrator username for Windows VMs"
  type        = string
  default     = "adminuser"
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password for Windows VMs"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Admin password must be at least 12 characters long."
  }
}

variable "sql_sa_password" {
  description = "SQL Server SA password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.sql_sa_password) >= 12
    error_message = "SQL SA password must be at least 12 characters long."
  }
}

variable "minio_root_user" {
  description = "MinIO root user"
  type        = string
  default     = "minioadmin"
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
  default     = "minioadmin123!"
}

# VM Sizes (provider-specific)
variable "web_vm_size" {
  description = "VM size for IIS/App server (provider-specific)"
  type        = string
  default     = "" # Will be set based on provider
}

variable "sql_vm_size" {
  description = "VM size for SQL Server (provider-specific)"
  type        = string
  default     = "" # Will be set based on provider
}

variable "minio_vm_size" {
  description = "VM size for MinIO server (provider-specific)"
  type        = string
  default     = "" # Will be set based on provider
}

# Storage
variable "web_vm_disk_size_gb" {
  description = "OS disk size for web server (GB)"
  type        = number
  default     = 128
}

variable "sql_vm_disk_size_gb" {
  description = "OS disk size for SQL server (GB)"
  type        = number
  default     = 256
}

variable "minio_vm_disk_size_gb" {
  description = "OS disk size for MinIO server (GB)"
  type        = number
  default     = 256
}

variable "sql_data_disk_size_gb" {
  description = "Data disk size for SQL Server (GB)"
  type        = number
  default     = 512
}

variable "minio_data_disk_size_gb" {
  description = "Data disk size for MinIO (GB)"
  type        = number
  default     = 1024
}

# Network
variable "vnet_address_space" {
  description = "Address space for VNet/VPC"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "web_subnet_address_prefix" {
  description = "Address prefix for web subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "sql_subnet_address_prefix" {
  description = "Address prefix for SQL subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "minio_subnet_address_prefix" {
  description = "Address prefix for MinIO subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# SSH Public Key
variable "ssh_public_key" {
  description = "SSH public key for future Linux support or Azure Linux VMs"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "SendMyFiles"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# AWS-specific variables
variable "aws_key_pair_name" {
  description = "AWS Key Pair name (for EC2 instances)"
  type        = string
  default     = ""
}

variable "aws_instance_profile" {
  description = "AWS IAM instance profile name"
  type        = string
  default     = ""
}

variable "aws_windows_ami_id" {
  description = "AWS Windows AMI ID (e.g., ami-06777e7ef7441deff for Windows Server 2025 Base). Leave empty for auto-detection."
  type        = string
  default     = ""
}

variable "aws_sql_ami_id" {
  description = "AWS SQL Server AMI ID. Leave empty for auto-detection."
  type        = string
  default     = ""
}

# GCP-specific variables
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""
}

variable "gcp_zone" {
  description = "GCP Zone (e.g., us-central1-a)"
  type        = string
  default     = ""
}
