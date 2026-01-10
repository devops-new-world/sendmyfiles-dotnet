# GCP Provider Module for SendMyFiles

# VPC Network
resource "google_compute_network" "main" {
  name                    = "sendmyfiles-vpc-${var.random_suffix}"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnets
resource "google_compute_subnetwork" "web" {
  name          = "web-subnet-${var.random_suffix}"
  ip_cidr_range = var.web_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id
}

resource "google_compute_subnetwork" "sql" {
  name          = "sql-subnet-${var.random_suffix}"
  ip_cidr_range = var.sql_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id
}

resource "google_compute_subnetwork" "minio" {
  name          = "minio-subnet-${var.random_suffix}"
  ip_cidr_range = var.minio_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id
}

# Firewall Rules
resource "google_compute_firewall" "web" {
  name    = "web-fw-${var.random_suffix}"
  network = google_compute_network.main.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3389", "5985"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "sql" {
  name    = "sql-fw-${var.random_suffix}"
  network = google_compute_network.main.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["1433", "3389"]
  }

  source_tags = ["web-server"]
  target_tags = ["sql-server"]
}

resource "google_compute_firewall" "minio" {
  name    = "minio-fw-${var.random_suffix}"
  network = google_compute_network.main.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["9000", "9001", "3389"]
  }

  source_tags = ["web-server"]
  target_tags = ["minio-server"]
}

# Web Server Instance
resource "google_compute_instance" "web" {
  name         = "sendmyfiles-web-${var.random_suffix}"
  machine_type = var.web_machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "windows-server-2022-dc-v20231212"
      size  = var.web_disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.web.name
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    windows-startup-script-ps1 = <<-EOF
      winrm quickconfig -q
      winrm set winrm/config/Service/Auth '@{Basic="true"}'
      winrm set winrm/config '@{MaxTimeoutms="1800000"}'
      winrm set winrm/config/Service '@{AllowUnencrypted="true"}'
    EOF
  }

  tags = ["web-server"]

  labels = var.tags
}

# SQL Server Instance
resource "google_compute_instance" "sql" {
  name         = "sendmyfiles-sql-${var.random_suffix}"
  machine_type = var.sql_machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "sql-server-2022-windows-2022-dc-v20231212"
      size  = var.sql_disk_size_gb
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.sql_data.id
    device_name = "sql-data"
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.sql.name
  }

  metadata = {
    windows-startup-script-ps1 = <<-EOF
      winrm quickconfig -q
      winrm set winrm/config/Service/Auth '@{Basic="true"}'
      winrm set winrm/config '@{MaxTimeoutms="1800000"}'
      winrm set winrm/config/Service '@{AllowUnencrypted="true"}'
    EOF
  }

  tags = ["sql-server"]

  labels = var.tags
}

# SQL Data Disk
resource "google_compute_disk" "sql_data" {
  name  = "sql-data-${var.random_suffix}"
  type  = "pd-ssd"
  zone  = var.zone
  size  = var.sql_data_disk_size_gb
  project = var.project_id
  labels = var.tags
}

# MinIO Server Instance
resource "google_compute_instance" "minio" {
  name         = "sendmyfiles-minio-${var.random_suffix}"
  machine_type = var.minio_machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "windows-server-2022-dc-v20231212"
      size  = var.minio_disk_size_gb
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.minio_data.id
    device_name = "minio-data"
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.minio.name
  }

  metadata = {
    windows-startup-script-ps1 = <<-EOF
      winrm quickconfig -q
      winrm set winrm/config/Service/Auth '@{Basic="true"}'
      winrm set winrm/config '@{MaxTimeoutms="1800000"}'
      winrm set winrm/config/Service '@{AllowUnencrypted="true"}'
    EOF
  }

  tags = ["minio-server"]

  labels = var.tags
}

# MinIO Data Disk
resource "google_compute_disk" "minio_data" {
  name  = "minio-data-${var.random_suffix}"
  type  = "pd-standard"
  zone  = var.zone
  size  = var.minio_data_disk_size_gb
  project = var.project_id
  labels = var.tags
}

