# AKS GitLab + AGIC Terraform

Deploy GitLab on Azure Kubernetes Service (AKS) with Application Gateway Ingress Controller (AGIC).

## Architecture

- **AKS Cluster**: 2 nodes (Standard_D2s_v3)
- **Application Gateway**: Ingress controller integrated with AKS
- **PostgreSQL**: Azure Database for PostgreSQL Flexible Server
- **Redis**: Azure Cache for Redis (Basic tier)
- **Storage**: Azure Storage Account for GitLab artifacts

## Prerequisites

- Azure CLI authenticated: `az login`
- Terraform >= 1.0
- kubectl configured to access the cluster
- Helm 3+ installed

## Setup

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Plan Deployment
```bash
terraform plan -out=tfplan
```

### 3. Apply Configuration
```bash
terraform apply tfplan
```

### 4. Get Terraform Outputs
```bash
terraform output
```

### 5. Configure kubectl
```bash
az aks get-credentials \
  --resource-group rg-gitlab \
  --name aks-gitlab-eip \
  --overwrite-existing
```

### 6. Deploy GitLab via Helm
```bash
helm repo add gitlab https://charts.gitlab.io
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f helm/values.yaml \
  --timeout 40m \
  --wait
```

## Configuration Files

- `terraform/main.tf` - Azure infrastructure resources
- `terraform/outputs.tf` - Output values for GitLab setup
- `helm/values.yaml` - GitLab Helm chart configuration
- `k8s/ingress.yaml` - Kubernetes Ingress resource
- `.github/workflows/deploy.yaml` - CI/CD automation

## Important Notes

- PostgreSQL password should be changed from default (set via `postgresql_admin_password` variable)
- Storage account name is generated with random suffix for global uniqueness
- Ensure Azure subscription has sufficient quota for all resources
- Initial GitLab setup may take 15-20 minutes