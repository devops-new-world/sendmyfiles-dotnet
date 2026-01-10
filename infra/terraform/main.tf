# Generate random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for provider-specific defaults
locals {
  # Default VM sizes by provider
  default_vm_sizes = {
    azure = {
      web   = "Standard_B2s"
      sql   = "Standard_D2s_v3"
      minio = "Standard_B2s"
    }
    aws = {
      web   = "t3.medium"
      sql   = "t3.large"
      minio = "t3.medium"
    }
    gcp = {
      web   = "e2-medium"
      sql   = "e2-standard-4"
      minio = "e2-medium"
    }
  }

  # Use provided sizes or defaults
  web_vm_size   = var.web_vm_size != "" ? var.web_vm_size : local.default_vm_sizes[var.cloud_provider].web
  sql_vm_size  = var.sql_vm_size != "" ? var.sql_vm_size : local.default_vm_sizes[var.cloud_provider].sql
  minio_vm_size = var.minio_vm_size != "" ? var.minio_vm_size : local.default_vm_sizes[var.cloud_provider].minio
}

# Deploy infrastructure based on selected provider
module "azure" {
  source = "./providers/azure"
  count  = var.cloud_provider == "azure" ? 1 : 0

  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  sql_sa_password      = var.sql_sa_password
  minio_root_user     = var.minio_root_user
  minio_root_password  = var.minio_root_password
  web_vm_size         = local.web_vm_size
  sql_vm_size         = local.sql_vm_size
  minio_vm_size      = local.minio_vm_size
  web_vm_disk_size_gb = var.web_vm_disk_size_gb
  sql_vm_disk_size_gb = var.sql_vm_disk_size_gb
  minio_vm_disk_size_gb = var.minio_vm_disk_size_gb
  sql_data_disk_size_gb = var.sql_data_disk_size_gb
  minio_data_disk_size_gb = var.minio_data_disk_size_gb
  vnet_address_space  = var.vnet_address_space
  web_subnet_address_prefix = var.web_subnet_address_prefix
  sql_subnet_address_prefix = var.sql_subnet_address_prefix
  minio_subnet_address_prefix = var.minio_subnet_address_prefix
  ssh_public_key      = var.ssh_public_key
  tags                = var.tags
  random_suffix       = random_id.suffix.hex
}

module "aws" {
  source = "./providers/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  resource_name_prefix = var.resource_group_name
  region               = var.location
  environment          = var.environment
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  sql_sa_password      = var.sql_sa_password
  minio_root_user      = var.minio_root_user
  minio_root_password  = var.minio_root_password
  web_instance_type    = local.web_vm_size
  sql_instance_type    = local.sql_vm_size
  minio_instance_type  = local.minio_vm_size
  web_disk_size_gb    = var.web_vm_disk_size_gb
  sql_disk_size_gb     = var.sql_vm_disk_size_gb
  minio_disk_size_gb   = var.minio_vm_disk_size_gb
  sql_data_disk_size_gb = var.sql_data_disk_size_gb
  minio_data_disk_size_gb = var.minio_data_disk_size_gb
  vpc_cidr             = var.vnet_address_space[0]
  web_subnet_cidr      = var.web_subnet_address_prefix
  sql_subnet_cidr      = var.sql_subnet_address_prefix
  minio_subnet_cidr    = var.minio_subnet_address_prefix
  key_pair_name        = var.aws_key_pair_name
  instance_profile     = var.aws_instance_profile
  ssh_public_key       = var.ssh_public_key
  tags                 = var.tags
  random_suffix        = random_id.suffix.hex
}

module "gcp" {
  source = "./providers/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  project_id           = var.gcp_project_id
  region               = var.location
  zone                 = var.gcp_zone
  environment          = var.environment
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  sql_sa_password      = var.sql_sa_password
  minio_root_user      = var.minio_root_user
  minio_root_password  = var.minio_root_password
  web_machine_type     = local.web_vm_size
  sql_machine_type     = local.sql_vm_size
  minio_machine_type   = local.minio_vm_size
  web_disk_size_gb     = var.web_vm_disk_size_gb
  sql_disk_size_gb     = var.sql_vm_disk_size_gb
  minio_disk_size_gb   = var.minio_vm_disk_size_gb
  sql_data_disk_size_gb = var.sql_data_disk_size_gb
  minio_data_disk_size_gb = var.minio_data_disk_size_gb
  network_cidr         = var.vnet_address_space[0]
  web_subnet_cidr      = var.web_subnet_address_prefix
  sql_subnet_cidr      = var.sql_subnet_address_prefix
  minio_subnet_cidr    = var.minio_subnet_address_prefix
  ssh_public_key       = var.ssh_public_key
  tags                 = var.tags
  random_suffix        = random_id.suffix.hex
}
