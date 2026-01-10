terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure providers conditionally
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}

provider "aws" {
  region = var.cloud_provider == "aws" ? var.location : "us-east-1"
}

provider "google" {
  project = var.gcp_project_id != "" ? var.gcp_project_id : null
  zone    = var.gcp_zone != "" ? var.gcp_zone : null
  region  = var.cloud_provider == "gcp" ? var.location : "us-central1"
}
