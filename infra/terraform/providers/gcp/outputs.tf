output "web_server_public_ip" {
  value = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "web_server_private_ip" {
  value = google_compute_instance.web.network_interface[0].network_ip
}

output "sql_server_private_ip" {
  value = google_compute_instance.sql.network_interface[0].network_ip
}

output "minio_server_private_ip" {
  value = google_compute_instance.minio.network_interface[0].network_ip
}

output "application_url" {
  value = "http://${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}"
}

output "connection_info" {
  value = {
    web_server = {
      public_ip  = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
      private_ip = google_compute_instance.web.network_interface[0].network_ip
    }
    sql_server = {
      private_ip = google_compute_instance.sql.network_interface[0].network_ip
      port       = 1433
    }
    minio_server = {
      private_ip = google_compute_instance.minio.network_interface[0].network_ip
      api_port   = 9000
      console_port = 9001
    }
  }
}

output "next_steps" {
  value = <<-EOT
    GCP infrastructure deployment completed!
    
    Next steps:
    1. Configure servers using Ansible playbooks
    2. Web Server: ${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}
    3. SQL Server: ${google_compute_instance.sql.network_interface[0].network_ip}:1433
    4. MinIO: ${google_compute_instance.minio.network_interface[0].network_ip}:9000
    
    Note: Get Windows password using:
    gcloud compute reset-windows-password ${google_compute_instance.web.name} --zone=${google_compute_instance.web.zone} --user=${var.admin_username}
  EOT
}

