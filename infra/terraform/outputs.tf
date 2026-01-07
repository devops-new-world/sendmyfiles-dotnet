output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "web_server_public_ip" {
  description = "Public IP address of the web server"
  value       = azurerm_public_ip.web.ip_address
}

output "web_server_fqdn" {
  description = "Fully qualified domain name of the web server"
  value       = azurerm_public_ip.web.fqdn
}

output "web_server_private_ip" {
  description = "Private IP address of the web server"
  value       = azurerm_network_interface.web.private_ip_address
}

output "sql_server_private_ip" {
  description = "Private IP address of the SQL server"
  value       = azurerm_network_interface.sql.private_ip_address
}

output "minio_server_private_ip" {
  description = "Private IP address of the MinIO server"
  value       = azurerm_network_interface.minio.private_ip_address
}

output "web_server_name" {
  description = "Name of the web server VM"
  value       = azurerm_windows_virtual_machine.web.name
}

output "sql_server_name" {
  description = "Name of the SQL server VM"
  value       = azurerm_windows_virtual_machine.sql.name
}

output "minio_server_name" {
  description = "Name of the MinIO server VM"
  value       = azurerm_windows_virtual_machine.minio.name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${azurerm_public_ip.web.ip_address}"
}

output "minio_console_url" {
  description = "URL to access MinIO console (from web server only)"
  value       = "http://${azurerm_network_interface.minio.private_ip_address}:9001"
}

output "connection_info" {
  description = "Connection information for the servers"
  value = {
    web_server = {
      public_ip  = azurerm_public_ip.web.ip_address
      private_ip = azurerm_network_interface.web.private_ip_address
      rdp        = "mstsc /v:${azurerm_public_ip.web.ip_address}"
    }
    sql_server = {
      private_ip = azurerm_network_interface.sql.private_ip_address
      port       = 1433
      connection = "Server=${azurerm_network_interface.sql.private_ip_address};Database=SendMyFiles;User Id=sa;Password=<your-sa-password>;TrustServerCertificate=True;"
    }
    minio_server = {
      private_ip = azurerm_network_interface.minio.private_ip_address
      api_port   = 9000
      console_port = 9001
      endpoint   = "${azurerm_network_interface.minio.private_ip_address}:9000"
    }
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    Infrastructure deployment completed successfully!
    
    Next steps:
    1. Configure servers using Ansible playbooks:
       cd ../ansible
       ansible-playbook playbooks/site.yml \
         --extra-vars "web_server_ip=${azurerm_network_interface.web.private_ip_address}" \
         --extra-vars "sql_server_ip=${azurerm_network_interface.sql.private_ip_address}" \
         --extra-vars "minio_server_ip=${azurerm_network_interface.minio.private_ip_address}" \
         --extra-vars "base_url=http://${azurerm_public_ip.web.ip_address}" \
         --extra-vars "admin_password=<your-admin-password>" \
         --extra-vars "sql_sa_password=<your-sql-password>" \
         --extra-vars "minio_root_password=<your-minio-password>"
    
    2. Or configure manually:
       - RDP to servers using the IPs above
       - Install IIS, .NET Framework 4.8 on web server
       - Configure SQL Server authentication
       - Install and configure MinIO
       - Deploy application files
    
    Server Information:
    - Web Server: ${azurerm_network_interface.web.private_ip_address} (Public: ${azurerm_public_ip.web.ip_address})
    - SQL Server: ${azurerm_network_interface.sql.private_ip_address}:1433
    - MinIO: ${azurerm_network_interface.minio.private_ip_address}:9000 (Console: :9001)
    
    See infra/ansible/README.md for detailed Ansible instructions.
  EOT
}

