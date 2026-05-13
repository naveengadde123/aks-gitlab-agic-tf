# Terraform Configuration

This directory contains the Terraform code to deploy GitLab on Azure Kubernetes Service (AKS) with Application Gateway Ingress Controller (AGIC).

## 📁 File Structure

```
terraform/
├── main.tf                    # Main infrastructure resources
├── variables.tf              # Input variables with validation
├── outputs.tf                # Output values
├── terraform.tfvars.example  # Example values (copy to terraform.tfvars)
├── .gitignore               # Git ignore file
└── README.md                # This file
```

## 🚀 Quick Start

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Create Your Configuration

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values
```

### 3. Validate Configuration

```bash
terraform validate
terraform fmt -recursive
```

### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

### 5. Apply Configuration

```bash
terraform apply tfplan
```

## 📝 Variables

### Required Variables
- None - all variables have defaults

### Important Variables to Customize

| Variable | Default | Description |
|----------|---------|-------------|
| `azure_region` | `central india` | Azure region for deployment |
| `resource_group_name` | `rg-gitlab` | Azure Resource Group name |
| `aks_node_count` | `2` | Number of AKS nodes (1-10) |
| `aks_vm_size` | `Standard_D2s_v3` | VM size for AKS nodes |
| `postgresql_admin_password` | `P@ssw0rd123!Gitlab` | PostgreSQL admin password |
| `gitlab_root_password` | `GitlabRoot@123` | GitLab root password |
| `postgresql_sku_name` | `B_Standard_B1ms` | PostgreSQL SKU |
| `redis_capacity` | `1` | Redis capacity in GB |

## 🎯 Common Configurations

### Development Environment
```bash
aks_node_count = 1
aks_vm_size = "Standard_B2s"
postgresql_sku_name = "B_Standard_B1ms"
redis_capacity = 0.25
```

### Production Environment
```bash
aks_node_count = 3
aks_vm_size = "Standard_D4s_v3"
app_gateway_capacity = 3
postgresql_sku_name = "D_Standard_D4s_v3"
redis_capacity = 6
redis_sku_name = "Premium"
storage_account_replication_type = "GRS"
```

## 📊 Outputs

After applying Terraform, you can get the values:

```bash
# Get all outputs
terraform output

# Get specific outputs
terraform output app_gateway_public_ip
terraform output postgresql_fqdn
terraform output redis_hostname
```

### Key Outputs
- **app_gateway_public_ip**: Public IP to access GitLab
- **postgresql_fqdn**: PostgreSQL server hostname
- **postgresql_username**: PostgreSQL admin username
- **redis_hostname**: Redis cache hostname
- **redis_port**: Redis port (6379)
- **storage_account_name**: Storage account name
- **aks_cluster_name**: AKS cluster name

## 🔄 State Management

Terraform state is stored locally in `.terraform/` directory.

### For Team Collaboration
Store state in Azure Storage (recommended):

```bash
# Create storage account for state
az storage account create \
  --name tfstate$RANDOM \
  --resource-group rg-terraform \
  --location centralindia \
  --sku Standard_LRS

# Configure backend in main.tf:
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "tfstate..."
    container_name       = "tfstate"
    key                  = "gitlab.tfstate"
  }
}
```

## ✅ Validation & Linting

### Validate syntax
```bash
terraform validate
```

### Format code
```bash
terraform fmt -recursive
```

### Security check (optional - requires checkov)
```bash
brew install checkov  # or apt-get install checkov
checkov -d .
```

## 🔐 Security Best Practices

### 1. Protect Sensitive Variables
- Never commit `terraform.tfvars` (already in .gitignore)
- Use Azure Key Vault for secrets in production
- Rotate passwords regularly

### 2. State File Security
- Store state in Azure Storage with encryption
- Enable versioning on state storage
- Restrict access to state file

### 3. Access Control
- Use Azure RBAC for who can apply Terraform
- Require approvals for apply in CI/CD

### 4. Audit & Logging
- Enable resource logging
- Monitor changes with Activity Log
- Use Azure Policy for compliance

## 🐛 Troubleshooting

### Common Errors

**Error: "storage account name already exists"**
- Storage account names are globally unique
- Change `storage_account_name_prefix` variable

**Error: "insufficient quota"**
- Azure subscriptions have quotas
- Request quota increase via Azure Portal
- Or change VM size to smaller SKU

**Error: "invalid variable value"**
- Check variable validation rules in variables.tf
- Run `terraform validate` for details

### Debug Mode

```bash
# Enable verbose logging
export TF_LOG=DEBUG
terraform plan

# Disable logging
unset TF_LOG
```

## 🧹 Cleanup

### Destroy All Resources
```bash
terraform destroy
# Type 'yes' when prompted
```

### Selective Destroy
```bash
# Remove only PostgreSQL
terraform destroy -target=azurerm_postgresql_flexible_server.pg
```

## 📚 Documentation

- [Terraform Docs](https://www.terraform.io/docs)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Guide](https://docs.microsoft.com/en-us/azure/aks/)
- [GitLab on Kubernetes](https://docs.gitlab.com/ee/install/kubernetes/)

## 💡 Tips

### Use workspaces for multiple environments
```bash
# Create dev and prod workspaces
terraform workspace new dev
terraform workspace new prod

# Switch between workspaces
terraform workspace select dev
terraform apply
```

### Generate documentation
```bash
# Install terraform-docs
brew install terraform-docs

# Generate docs
terraform-docs md . > TERRAFORM.md
```

### Automatic formatting in VS Code
Add to `.vscode/settings.json`:
```json
{
  "[hcl]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "hashicorp.hcl"
  }
}
```

## 📞 Support

For issues:
1. Check Terraform logs: `terraform plan -json | jq`
2. Review Azure Activity Log in Portal
3. Check AKS cluster logs: `az aks get-diagnostics`
4. Consult [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform/)

---

**Last Updated**: May 13, 2026  
**Terraform Version**: >= 1.0  
**Azure Provider**: ~> 3.0
