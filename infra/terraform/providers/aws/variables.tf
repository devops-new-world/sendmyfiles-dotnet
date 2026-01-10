variable "resource_name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sql_sa_password" {
  type      = string
  sensitive = true
}

variable "minio_root_user" {
  type = string
}

variable "minio_root_password" {
  type      = string
  sensitive = true
}

variable "web_instance_type" {
  type = string
}

variable "sql_instance_type" {
  type = string
}

variable "minio_instance_type" {
  type = string
}

variable "web_disk_size_gb" {
  type = number
}

variable "sql_disk_size_gb" {
  type = number
}

variable "minio_disk_size_gb" {
  type = number
}

variable "sql_data_disk_size_gb" {
  type = number
}

variable "minio_data_disk_size_gb" {
  type = number
}

variable "vpc_cidr" {
  type = string
}

variable "web_subnet_cidr" {
  type = string
}

variable "sql_subnet_cidr" {
  type = string
}

variable "minio_subnet_cidr" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = ""
}

variable "instance_profile" {
  type    = string
  default = ""
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "random_suffix" {
  type = string
}

variable "windows_ami_id" {
  type        = string
  default     = ""
  description = "Custom Windows AMI ID (e.g., ami-06777e7ef7441deff for Windows Server 2025 Base). Leave empty to use auto-detection."
}

variable "sql_ami_id" {
  type        = string
  default     = ""
  description = "Custom SQL Server AMI ID. Leave empty to use auto-detection or Windows AMI."
}
