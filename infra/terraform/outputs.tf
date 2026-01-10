# Outputs based on selected provider
output "cloud_provider" {
  description = "Selected cloud provider"
  value       = var.cloud_provider
}

# Azure outputs
output "web_server_public_ip" {
  description = "Public IP address of the web server"
  value       = var.cloud_provider == "azure" ? module.azure[0].web_server_public_ip : (var.cloud_provider == "aws" ? module.aws[0].web_server_public_ip : module.gcp[0].web_server_public_ip)
}

output "web_server_private_ip" {
  description = "Private IP address of the web server"
  value       = var.cloud_provider == "azure" ? module.azure[0].web_server_private_ip : (var.cloud_provider == "aws" ? module.aws[0].web_server_private_ip : module.gcp[0].web_server_private_ip)
}

output "sql_server_private_ip" {
  description = "Private IP address of the SQL server"
  value       = var.cloud_provider == "azure" ? module.azure[0].sql_server_private_ip : (var.cloud_provider == "aws" ? module.aws[0].sql_server_private_ip : module.gcp[0].sql_server_private_ip)
}

output "minio_server_private_ip" {
  description = "Private IP address of the MinIO server"
  value       = var.cloud_provider == "azure" ? module.azure[0].minio_server_private_ip : (var.cloud_provider == "aws" ? module.aws[0].minio_server_private_ip : module.gcp[0].minio_server_private_ip)
}

output "application_url" {
  description = "URL to access the application"
  value       = var.cloud_provider == "azure" ? module.azure[0].application_url : (var.cloud_provider == "aws" ? module.aws[0].application_url : module.gcp[0].application_url)
}

output "connection_info" {
  description = "Connection information for the servers"
  value = var.cloud_provider == "azure" ? module.azure[0].connection_info : (var.cloud_provider == "aws" ? module.aws[0].connection_info : module.gcp[0].connection_info)
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = var.cloud_provider == "azure" ? module.azure[0].next_steps : (var.cloud_provider == "aws" ? module.aws[0].next_steps : module.gcp[0].next_steps)
}
