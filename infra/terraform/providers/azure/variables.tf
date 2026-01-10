variable "resource_group_name" {
  type = string
}

variable "location" {
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

variable "web_vm_size" {
  type = string
}

variable "sql_vm_size" {
  type = string
}

variable "minio_vm_size" {
  type = string
}

variable "web_vm_disk_size_gb" {
  type = number
}

variable "sql_vm_disk_size_gb" {
  type = number
}

variable "minio_vm_disk_size_gb" {
  type = number
}

variable "sql_data_disk_size_gb" {
  type = number
}

variable "minio_data_disk_size_gb" {
  type = number
}

variable "vnet_address_space" {
  type = list(string)
}

variable "web_subnet_address_prefix" {
  type = string
}

variable "sql_subnet_address_prefix" {
  type = string
}

variable "minio_subnet_address_prefix" {
  type = string
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
