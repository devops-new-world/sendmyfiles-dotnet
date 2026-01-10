output "web_server_public_ip" {
  value = azurerm_public_ip.web.ip_address
}

output "web_server_private_ip" {
  value = azurerm_network_interface.web.private_ip_address
}

output "sql_server_private_ip" {
  value = azurerm_network_interface.sql.private_ip_address
}

output "minio_server_private_ip" {
  value = azurerm_network_interface.minio.private_ip_address
}

output "application_url" {
  value = "http://${azurerm_public_ip.web.ip_address}"
}

output "connection_info" {
  value = {
    web_server = {
      public_ip  = azurerm_public_ip.web.ip_address
      private_ip = azurerm_network_interface.web.private_ip_address
    }
    sql_server = {
      private_ip = azurerm_network_interface.sql.private_ip_address
      port       = 1433
    }
    minio_server = {
      private_ip = azurerm_network_interface.minio.private_ip_address
      api_port   = 9000
      console_port = 9001
    }
  }
}

output "next_steps" {
  value = <<-EOT
    Azure infrastructure deployment completed!
    
    Next steps:
    1. Configure servers using Ansible playbooks
    2. Web Server: ${azurerm_public_ip.web.ip_address}
    3. SQL Server: ${azurerm_network_interface.sql.private_ip_address}:1433
    4. MinIO: ${azurerm_network_interface.minio.private_ip_address}:9000
  EOT
}

