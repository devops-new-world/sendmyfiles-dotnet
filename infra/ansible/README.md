# Ansible Playbooks for SendMyFiles

This directory contains Ansible playbooks for configuring and deploying the SendMyFiles application after infrastructure is provisioned by Terraform.

## Prerequisites

1. **Ansible** >= 2.9 installed
   ```bash
   pip install ansible
   pip install pywinrm  # Required for Windows hosts
   ```

2. **Terraform outputs** - Get server IPs from Terraform:
   ```bash
   cd ../terraform
   terraform output
   ```

3. **Windows hosts** must have WinRM enabled (handled by Terraform)

## Quick Start

### 1. Get Terraform Outputs

```bash
cd ../terraform
terraform output -json > ../ansible/terraform-outputs.json
```

### 2. Update Inventory

Edit `group_vars/all.yml` or use `--extra-vars`:

```bash
ansible-playbook playbooks/site.yml \
  --extra-vars "web_server_ip=$(terraform -chdir=../terraform output -raw web_server_private_ip)" \
  --extra-vars "sql_server_ip=$(terraform -chdir=../terraform output -raw sql_server_private_ip)" \
  --extra-vars "minio_server_ip=$(terraform -chdir=../terraform output -raw minio_server_private_ip)" \
  --extra-vars "admin_password=YourPassword" \
  --extra-vars "sql_sa_password=YourSQLPassword" \
  --extra-vars "minio_root_password=YourMinIOPassword"
```

### 3. Run Playbooks

**Configure all servers:**
```bash
ansible-playbook playbooks/site.yml
```

**Configure individual servers:**
```bash
# Web server only
ansible-playbook playbooks/web-server.yml

# SQL server only
ansible-playbook playbooks/sql-server.yml

# MinIO server only
ansible-playbook playbooks/minio-server.yml
```

## Playbooks

### `playbooks/web-server.yml`
Configures the web server:
- Installs IIS and required features
- Installs .NET Framework 4.8
- Configures Windows Firewall
- Creates application directories
- Deploys application files
- Configures Web.config

### `playbooks/sql-server.yml`
Configures SQL Server:
- Configures Windows Firewall
- Initializes data disk
- Creates SQL configuration script
- Sets up database

### `playbooks/minio-server.yml`
Configures MinIO:
- Installs MinIO
- Configures Windows Firewall
- Initializes data disk
- Sets up MinIO as Windows service

## Configuration Variables

Set these in `group_vars/all.yml` or via `--extra-vars`:

| Variable | Description | Required |
|----------|-------------|----------|
| `admin_username` | Windows admin username | Yes |
| `admin_password` | Windows admin password | Yes |
| `sql_sa_password` | SQL Server SA password | Yes |
| `minio_root_user` | MinIO root user | Yes |
| `minio_root_password` | MinIO root password | Yes |
| `web_server_ip` | Web server private IP | Yes |
| `sql_server_ip` | SQL server private IP | Yes |
| `minio_server_ip` | MinIO server private IP | Yes |
| `base_url` | Application base URL | Yes |
| `smtp_server` | SMTP server | Yes |
| `smtp_username` | SMTP username | Yes |
| `smtp_password` | SMTP password | Yes |
| `smtp_from_email` | SMTP from email | Yes |

## Using Ansible Vault for Secrets

For production, use Ansible Vault to encrypt sensitive variables:

```bash
# Create vault file
ansible-vault create group_vars/vault.yml

# Edit vault file
ansible-vault edit group_vars/vault.yml

# Run playbook with vault
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## Example: Complete Deployment

```bash
# 1. Deploy infrastructure with Terraform
cd ../terraform
terraform apply

# 2. Get outputs
WEB_IP=$(terraform output -raw web_server_private_ip)
SQL_IP=$(terraform output -raw sql_server_private_ip)
MINIO_IP=$(terraform output -raw minio_server_private_ip)
PUBLIC_IP=$(terraform output -raw web_server_public_ip)

# 3. Configure with Ansible
cd ../ansible
ansible-playbook playbooks/site.yml \
  --extra-vars "web_server_ip=$WEB_IP" \
  --extra-vars "sql_server_ip=$SQL_IP" \
  --extra-vars "minio_server_ip=$MINIO_IP" \
  --extra-vars "base_url=http://$PUBLIC_IP" \
  --extra-vars "admin_password=YourPassword" \
  --extra-vars "sql_sa_password=YourSQLPassword" \
  --extra-vars "minio_root_password=YourMinIOPassword" \
  --extra-vars "smtp_username=your-email@gmail.com" \
  --extra-vars "smtp_password=your-app-password" \
  --extra-vars "smtp_from_email=your-email@gmail.com"
```

## Troubleshooting

### WinRM Connection Issues
```bash
# Test WinRM connection
ansible web_servers -m win_ping
```

### Firewall Issues
Ensure WinRM port (5985) is open in Azure NSG and Windows Firewall.

### Module Not Found
```bash
pip install pywinrm
```

### Timeout Issues
Increase timeout in `ansible.cfg`:
```ini
[winrm]
connection_timeout = 60
read_timeout = 60
```

## Integration with GitHub Actions

You can add Ansible steps to your GitHub Actions workflow:

```yaml
- name: Configure Infrastructure with Ansible
  run: |
    cd infra/ansible
    ansible-playbook playbooks/site.yml \
      --extra-vars "web_server_ip=${{ steps.terraform.outputs.web_server_private_ip }}" \
      --extra-vars "sql_server_ip=${{ steps.terraform.outputs.sql_server_private_ip }}" \
      --extra-vars "minio_server_ip=${{ steps.terraform.outputs.minio_server_private_ip }}"
```

## Next Steps

After running Ansible playbooks:
1. Verify IIS is running on web server
2. Access application at the base URL
3. Configure MinIO bucket from web server
4. Run Database/Schema.sql on SQL server

