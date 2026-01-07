# SendMyFiles - Terraform Infrastructure

This Terraform configuration provisions a 3-server infrastructure for SendMyFiles on Azure:

> **💡 Tip**: You can also deploy using GitHub Actions! See [.github/workflows/README.md](../../.github/workflows/README.md) for automated deployment with manual triggers and customizable options.

1. **Web Server** - IIS with .NET Framework 4.8
2. **SQL Server** - Microsoft SQL Server 2022
3. **MinIO Server** - S3-compatible object storage

## Prerequisites

1. **Azure Account** with active subscription
2. **Azure CLI** installed and configured
   ```bash
   az login
   az account set --subscription "Your Subscription ID"
   ```
3. **Terraform** >= 1.0 installed
   - Download from: https://www.terraform.io/downloads
4. **PowerShell** (for Windows) or **Bash** (for Linux/Mac)

## Quick Start

### 1. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:
- `admin_password` - Administrator password for Windows VMs (min 12 chars)
- `sql_sa_password` - SQL Server SA password (min 12 chars)
- `minio_root_password` - MinIO root password
- `location` - Azure region (e.g., "East US", "West Europe")

### 2. Initialize Terraform

```bash
cd infra/terraform
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

This will show you what resources will be created. Review carefully.

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Get Outputs

After deployment, get connection information:

```bash
terraform output
```

## Infrastructure Components

### Network Architecture

```
┌─────────────────────────────────────────┐
│         Virtual Network (10.0.0.0/16)   │
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Web Subnet   │  │ SQL Subnet   │   │
│  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │   │
│  │              │  │              │   │
│  │ Web Server   │  │ SQL Server   │   │
│  │ (Public IP)  │  │ (Private)     │   │
│  └──────────────┘  └──────────────┘   │
│                                         │
│  ┌──────────────┐                      │
│  │ MinIO Subnet │                      │
│  │ 10.0.3.0/24  │                      │
│  │              │                      │
│  │ MinIO Server │                      │
│  │ (Private)    │                      │
│  └──────────────┘                      │
└─────────────────────────────────────────┘
```

### Security Groups

- **Web Server NSG**: Allows HTTP (80), HTTPS (443), RDP (3389)
- **SQL Server NSG**: Allows SQL (1433) from web subnet only, RDP (3389)
- **MinIO Server NSG**: Allows MinIO API (9000) and Console (9001) from web subnet only, RDP (3389)

### Virtual Machines

| Server | VM Size | vCPUs | RAM | OS Disk | Data Disk |
|--------|---------|-------|-----|---------|-----------|
| Web | Standard_D2s_v3 | 2 | 8 GB | 128 GB | - |
| SQL | Standard_D4s_v3 | 4 | 16 GB | 256 GB | 512 GB |
| MinIO | Standard_D2s_v3 | 2 | 8 GB | 256 GB | 1024 GB |

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

1. **Connect to Web Server**
   ```bash
   terraform output web_server_public_ip
   mstsc /v:<public-ip>
   ```

2. **Install IIS and .NET Framework 4.8**
   - Install IIS via Server Manager
   - Download and install .NET Framework 4.8

3. **Deploy Application**
   - Copy application files to `C:\inetpub\wwwroot\SendMyFiles`
   - Configure `Web.config` with connection strings

4. **Configure SQL Server**
   - RDP to SQL Server VM
   - Enable Mixed Mode Authentication
   - Run `Database/Schema.sql`

5. **Configure MinIO**
   - Install MinIO on MinIO server
   - Create bucket and configure access

## Outputs

After deployment, Terraform provides:

- `web_server_public_ip` - Public IP to access the application
- `web_server_private_ip` - Private IP of web server
- `sql_server_private_ip` - Private IP of SQL server
- `minio_server_private_ip` - Private IP of MinIO server
- `application_url` - URL to access the application
- `connection_info` - Detailed connection information

## Cost Estimation

Approximate monthly costs (varies by region):

- **Web Server** (Standard_D2s_v3): ~$70/month
- **SQL Server** (Standard_D4s_v3): ~$140/month
- **MinIO Server** (Standard_D2s_v3): ~$70/month
- **Storage**: ~$50/month (premium disks)
- **Network**: ~$10/month
- **Total**: ~$340/month

**Note**: SQL Server Developer edition is free but requires license for production use.

## Troubleshooting

### Web Server Not Accessible

1. Check NSG rules allow HTTP/HTTPS
2. Verify IIS is running: `Get-Service W3SVC`
3. Check firewall: `Get-NetFirewallRule | Where-Object DisplayName -like "*HTTP*"`

### SQL Server Connection Issues

1. Verify SQL Server service is running
2. Check SQL Server Authentication is enabled (Mixed Mode)
3. Verify NSG allows port 1433 from web subnet
4. Test connection: `Test-NetConnection -ComputerName <sql-ip> -Port 1433`

### MinIO Not Accessible

1. Check MinIO service is running: `Get-Service MinIO`
2. Verify NSG allows ports 9000/9001 from web subnet
3. Check MinIO logs: `C:\AzureData\CustomDataSetupScript.log`

### Custom Scripts Not Running

1. Check logs: `C:\AzureData\CustomDataSetupScript.log`
2. Verify VM has internet access
3. Check Windows Event Viewer for errors

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources and data!

## Customization

### Change VM Sizes

Edit `terraform.tfvars`:

```hcl
web_vm_size   = "Standard_B2s"  # Smaller, cheaper option
sql_vm_size   = "Standard_D2s_v3" # Smaller SQL server
minio_vm_size = "Standard_B2s"   # Smaller MinIO server
```

### Change Disk Sizes

```hcl
sql_data_disk_size_gb   = 256  # Smaller data disk
minio_data_disk_size_gb = 512  # Smaller storage
```

### Use Different Region

```hcl
location = "West Europe"  # or any Azure region
```

## Security Best Practices

1. **Change Default Passwords**: Update all passwords after first login
2. **Restrict RDP Access**: Update NSG rules to allow RDP only from your IP
3. **Enable HTTPS**: Install SSL certificate on web server
4. **Use Azure Key Vault**: Store secrets in Key Vault instead of variables
5. **Regular Updates**: Keep Windows and SQL Server updated
6. **Backup Strategy**: Configure automated backups for SQL Server

## Additional Resources

- [Azure Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [SendMyFiles Architecture](../INFRASTRUCTURE.md)
- [Deployment Guide](../DEPLOYMENT.md)

## Support

For issues:
1. Check Terraform logs: `terraform apply -debug`
2. Check VM logs: `C:\AzureData\CustomDataSetupScript.log`
3. Review Azure Portal for resource status

