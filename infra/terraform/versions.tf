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
# Note: Terraform initializes all providers, but they will only be used based on cloud_provider variable
# Azure Provider - only authenticates when using Azure
# Note: When not using Azure, this provider will try to authenticate but fail
# This is expected and OK since the azure module has count=0 when not using Azure
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
  # Credentials set via ARM_* environment variables or Azure CLI
  # When not using Azure and credentials are not set, authentication will fail
  # but this is acceptable since the module won't be used (count=0)
  skip_provider_registration = true
}

# AWS Provider - skips validation when not using AWS
provider "aws" {
  region = var.cloud_provider == "aws" ? var.location : "us-east-1"
  # Credentials set via AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY environment variables
  # Skip validation when not using AWS to avoid errors
  skip_credentials_validation = var.cloud_provider != "aws"
  skip_metadata_api_check     = var.cloud_provider != "aws"
  skip_region_validation      = var.cloud_provider != "aws"
  skip_requesting_account_id  = var.cloud_provider != "aws"
}

# GCP Provider - uses dummy project when not using GCP
provider "google" {
  project = var.cloud_provider == "gcp" && var.gcp_project_id != "" ? var.gcp_project_id : "dummy-project"
  zone    = var.cloud_provider == "gcp" && var.gcp_zone != "" ? var.gcp_zone : "us-central1-a"
  region  = var.cloud_provider == "gcp" ? var.location : "us-central1"
  # Credentials set via GOOGLE_APPLICATION_CREDENTIALS environment variable
  # When not using GCP, dummy credentials are provided to avoid errors
}
