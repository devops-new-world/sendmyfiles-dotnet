output "web_server_public_ip" {
  value = aws_eip.web.public_ip
}

output "web_server_private_ip" {
  value = aws_instance.web.private_ip
}

output "sql_server_private_ip" {
  value = aws_instance.sql.private_ip
}

output "minio_server_private_ip" {
  value = aws_instance.minio.private_ip
}

output "application_url" {
  value = "http://${aws_eip.web.public_ip}"
}

output "connection_info" {
  value = {
    web_server = {
      public_ip  = aws_eip.web.public_ip
      private_ip = aws_instance.web.private_ip
    }
    sql_server = {
      private_ip = aws_instance.sql.private_ip
      port       = 1433
    }
    minio_server = {
      private_ip   = aws_instance.minio.private_ip
      api_port     = 9000
      console_port = 9001
    }
  }
}

output "next_steps" {
  value = <<-EOT
    AWS infrastructure deployment completed!
    
    Next steps:
    1. Configure servers using Ansible playbooks
    2. Web Server: ${aws_eip.web.public_ip}
    3. SQL Server: ${aws_instance.sql.private_ip}:1433
    4. MinIO: ${aws_instance.minio.private_ip}:9000
    
    Note: Get Windows password using:
    aws ec2 get-password-data --instance-id ${aws_instance.web.id} --priv-launch-key <your-key.pem>
  EOT
}

