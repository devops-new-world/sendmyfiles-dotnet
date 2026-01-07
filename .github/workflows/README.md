# GitHub Actions Workflows

## Deploy Infrastructure Workflow

The `deploy-infrastructure.yml` workflow allows you to deploy the SendMyFiles infrastructure to Azure using Terraform through GitHub Actions.

### Prerequisites

Before using this workflow, you need to configure the following GitHub Secrets:

1. **AZURE_SUBSCRIPTION_ID** - Your Azure subscription ID
2. **AZURE_CLIENT_ID** - Azure service principal client ID
3. **AZURE_CLIENT_SECRET** - Azure service principal client secret
4. **AZURE_TENANT_ID** - Azure tenant ID
5. **AZURE_ADMIN_PASSWORD** - Administrator password for Windows VMs (min 12 characters)
6. **AZURE_SQL_SA_PASSWORD** - SQL Server SA password (min 12 characters)
7. **AZURE_MINIO_ROOT_PASSWORD** - MinIO root password

### Setting Up Azure Service Principal

1. Create a service principal:
   ```bash
   az ad sp create-for-rbac --name "SendMyFiles-GitHubActions" \
     --role contributor \
     --scopes /subscriptions/{subscription-id} \
     --sdk-auth
   ```

2. Copy the output JSON and extract the values:
   - `clientId` → `AZURE_CLIENT_ID`
   - `clientSecret` → `AZURE_CLIENT_SECRET`
   - `subscriptionId` → `AZURE_SUBSCRIPTION_ID`
   - `tenantId` → `AZURE_TENANT_ID`

3. Add these as secrets in your GitHub repository:
   - Go to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Add each secret

### Using the Workflow

1. Go to the **Actions** tab in your GitHub repository
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Fill in the inputs:
   - **Machine Count**: Choose 1, 2, or 3 servers (default: 3)
     - 1 = All on single server
     - 2 = Web + SQL on separate servers
     - 3 = Web, SQL, and MinIO on separate servers
   - **Web VM Size**: Size for web server (default: Standard_B2s, similar to AWS t3.medium)
   - **SQL VM Size**: Size for SQL server (default: Standard_D2s_v3)
   - **MinIO VM Size**: Size for MinIO server (default: Standard_B2s)
   - **SSH Public Key**: Optional SSH public key for future Linux support
   - **Environment**: dev, staging, or prod (default: prod)
   - **Location**: Azure region (default: East US)
5. Click **Run workflow**

### Workflow Inputs

| Input | Description | Default | Options |
|-------|-------------|---------|---------|
| `machine_count` | Number of machines to deploy | 3 | 1, 2, 3 |
| `web_vm_size` | Web server VM size | Standard_B2s | Standard_B1s, Standard_B1ms, Standard_B2s, Standard_B2ms, Standard_D2s_v3, Standard_D4s_v3 |
| `sql_vm_size` | SQL server VM size | Standard_D2s_v3 | Standard_B2s, Standard_B2ms, Standard_D2s_v3, Standard_D4s_v3, Standard_D8s_v3 |
| `minio_vm_size` | MinIO server VM size | Standard_B2s | Standard_B1s, Standard_B1ms, Standard_B2s, Standard_B2ms, Standard_D2s_v3, Standard_D4s_v3 |
| `ssh_public_key` | SSH public key (optional) | - | Any valid SSH public key |
| `environment` | Environment name | prod | dev, staging, prod |
| `location` | Azure region | East US | Any valid Azure region |

### VM Size Reference

| Azure VM Size | vCPUs | RAM | Similar to AWS |
|---------------|-------|-----|----------------|
| Standard_B1s | 1 | 1 GB | t3.micro |
| Standard_B1ms | 1 | 2 GB | t3.small |
| Standard_B2s | 2 | 4 GB | **t3.medium** |
| Standard_B2ms | 2 | 8 GB | t3.large |
| Standard_D2s_v3 | 2 | 8 GB | t3.xlarge |
| Standard_D4s_v3 | 4 | 16 GB | - |

### Tags Applied to Resources

All resources are automatically tagged with:
- `Project`: SendMyFiles
- `Environment`: dev/staging/prod (from input)
- `ManagedBy`: Terraform
- `DeployedBy`: GitHubActions
- `WorkflowRun`: GitHub workflow run ID
- `CommitSHA`: Git commit SHA
- `Repository`: GitHub repository name
- `Branch`: Git branch name

### Workflow Steps

1. **Checkout code** - Checks out the repository
2. **Setup Terraform** - Installs Terraform
3. **Azure Login** - Authenticates with Azure using service principal
4. **Create terraform.tfvars** - Generates Terraform variables file from inputs
5. **Terraform Init** - Initializes Terraform
6. **Terraform Plan** - Creates execution plan
7. **Terraform Apply** - Applies the infrastructure
8. **Get Terraform Outputs** - Displays deployment summary

### Outputs

After successful deployment, the workflow will display:
- Web server public IP
- SQL server private IP
- MinIO server private IP
- Application URL

### Troubleshooting

#### Authentication Errors
- Verify all Azure secrets are correctly set
- Check service principal has Contributor role
- Ensure subscription ID is correct

#### Terraform Errors
- Check Terraform logs in workflow output
- Verify VM sizes are available in selected region
- Ensure passwords meet requirements (min 12 characters)

#### Resource Creation Failures
- Check Azure quota limits
- Verify region supports selected VM sizes
- Review Azure Portal for detailed error messages

### Cost Optimization

For development/testing, use:
- `Standard_B2s` for all VMs (similar to AWS t3.medium)
- Smaller disk sizes
- Single server deployment (machine_count: 1)

For production, use:
- `Standard_D2s_v3` or larger for web server
- `Standard_D4s_v3` or larger for SQL server
- Separate servers (machine_count: 3)

### Security Notes

- Passwords are stored as GitHub Secrets (encrypted)
- SSH keys are optional and stored in Terraform state
- All resources are tagged for tracking and cost management
- Network security groups restrict access appropriately

### Next Steps After Deployment

1. RDP to web server using the public IP
2. Deploy your SendMyFiles application
3. Configure Web.config with SQL and MinIO private IPs
4. Run Database/Schema.sql on SQL server
5. Configure MinIO bucket from web server

See [infra/terraform/README.md](../infra/terraform/README.md) for detailed post-deployment steps.

