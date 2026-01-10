# SendMyFiles - Multi-Cloud Terraform Infrastructure

This Terraform configuration provisions a 3-server infrastructure for SendMyFiles on **Azure, AWS, or GCP**:

> **💡 Tip**: You can also deploy using GitHub Actions! See [.github/workflows/README.md](../../.github/workflows/README.md) for automated deployment with manual triggers and customizable options.

1. **Web Server** - IIS with .NET Framework 4.8
2. **SQL Server** - Microsoft SQL Server 2022
3. **MinIO Server** - S3-compatible object storage

## Supported Cloud Providers

- ✅ **Azure** (default)
- ✅ **AWS**
- ✅ **GCP**

## Prerequisites

### For Azure:
1. **Azure Account** with active subscription
2. **Azure CLI** installed and configured
   ```bash
   az login
   az account set --subscription "Your Subscription ID"
   ```

### For AWS:
1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
   ```bash
   aws configure
   ```

### For GCP:
1. **GCP Project** with billing enabled
2. **gcloud CLI** installed and configured
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

### Common:
3. **Terraform** >= 1.0 installed
   - Download from: https://www.terraform.io/downloads

## Quick Start

### 1. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:
- `cloud_provider` - Choose: `azure`, `aws`, or `gcp`
- `location` - Cloud region (provider-specific)
- `admin_password` - Administrator password for Windows VMs (min 12 chars)
- `sql_sa_password` - SQL Server SA password (min 12 chars)
- `minio_root_password` - MinIO root password
- Provider-specific settings (see below)

### 2. Provider-Specific Configuration

#### Azure:
```hcl
cloud_provider = "azure"
location       = "East US"
```

#### AWS:
```hcl
cloud_provider = "aws"
location       = "us-east-1"
aws_key_pair_name = "your-key-pair"  # Optional
```

#### GCP:
```hcl
cloud_provider = "gcp"
location       = "us-central1"
gcp_project_id = "your-project-id"
gcp_zone       = "us-central1-a"
```

### 3. Initialize Terraform

```bash
cd infra/terraform
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

This will show you what resources will be created. Review carefully.

### 5. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 6. Get Outputs

After deployment, get connection information:

```bash
terraform output
```

## Default VM Sizes by Provider

| Provider | Web Server | SQL Server | MinIO Server |
|----------|------------|------------|-------------|
| **Azure** | Standard_B2s | Standard_D2s_v3 | Standard_B2s |
| **AWS** | t3.medium | t3.large | t3.medium |
| **GCP** | e2-medium | e2-standard-4 | e2-medium |

You can override these by setting `web_vm_size`, `sql_vm_size`, and `minio_vm_size` in `terraform.tfvars`.

## Infrastructure Components

### Network Architecture

All providers create:
- Virtual Network/VPC with 3 subnets (Web, SQL, MinIO)
- Security Groups/Firewall Rules
- Public IP for web server only
- Private IPs for SQL and MinIO servers

### Security

- **Web Server**: HTTP (80), HTTPS (443), RDP (3389), WinRM (5985)
- **SQL Server**: SQL (1433) from web subnet only, RDP (3389)
- **MinIO**: API (9000) and Console (9001) from web subnet only, RDP (3389)

## Post-Deployment Steps

### Option 1: Use Ansible Playbooks (Recommended)

After Terraform deployment, use Ansible to configure and deploy:

```bash
cd ../ansible
ansible-playbook playbooks/site.yml \
  --extra-vars "web_server_ip=$(terraform -chdir=../terraform output -raw web_server_private_ip)" \
  --extra-vars "sql_server_ip=$(terraform -chdir=../terraform output -raw sql_server_private_ip)" \
  --extra-vars "minio_server_ip=$(terraform -chdir=../terraform output -raw minio_server_private_ip)" \
  --extra-vars "base_url=http://$(terraform -chdir=../terraform output -raw web_server_public_ip)" \
  --extra-vars "admin_password=<your-admin-password>" \
  --extra-vars "sql_sa_password=<your-sql-password>" \
  --extra-vars "minio_root_password=<your-minio-password>"
```

See **[infra/ansible/README.md](../ansible/README.md)** for detailed Ansible instructions.

### Option 2: Manual Configuration

1. **Connect to Web Server** using RDP
2. **Install IIS and .NET Framework 4.8**
3. **Deploy Application** files
4. **Configure SQL Server** (enable Mixed Mode, create database)
5. **Configure MinIO** (install and create bucket)

## Cost Estimation

Approximate monthly costs (varies by region and provider):

| Provider | Web Server | SQL Server | MinIO Server | Total |
|----------|------------|------------|--------------|-------|
| **Azure** | ~$70 | ~$140 | ~$70 | ~$280 |
| **AWS** | ~$60 | ~$120 | ~$60 | ~$240 |
| **GCP** | ~$50 | ~$100 | ~$50 | ~$200 |

*Note: SQL Server Developer edition is free but requires license for production use.*

## Troubleshooting

### Provider Authentication Issues

**Azure:**
```bash
az login
az account list
```

**AWS:**
```bash
aws configure
aws sts get-caller-identity
```

**GCP:**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Terraform Errors

- Check provider credentials are configured
- Verify VM sizes are available in selected region
- Ensure passwords meet requirements (min 12 characters)
- Check quota limits in your cloud account

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources and data!

## Related Documentation

- **[infra/ansible/README.md](../ansible/README.md)** - Ansible configuration and deployment
- **[.github/workflows/README.md](../../.github/workflows/README.md)** - GitHub Actions deployment
- **[INFRASTRUCTURE.md](../../INFRASTRUCTURE.md)** - Architecture documentation
