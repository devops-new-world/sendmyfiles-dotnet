variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "environment" { type = string }
variable "admin_username" { type = string }
variable "admin_password" { type = string; sensitive = true }
variable "sql_sa_password" { type = string; sensitive = true }
variable "minio_root_user" { type = string }
variable "minio_root_password" { type = string; sensitive = true }
variable "web_machine_type" { type = string }
variable "sql_machine_type" { type = string }
variable "minio_machine_type" { type = string }
variable "web_disk_size_gb" { type = number }
variable "sql_disk_size_gb" { type = number }
variable "minio_disk_size_gb" { type = number }
variable "sql_data_disk_size_gb" { type = number }
variable "minio_data_disk_size_gb" { type = number }
variable "network_cidr" { type = string }
variable "web_subnet_cidr" { type = string }
variable "sql_subnet_cidr" { type = string }
variable "minio_subnet_cidr" { type = string }
variable "ssh_public_key" { type = string; default = "" }
variable "tags" { type = map(string) }
variable "random_suffix" { type = string }

