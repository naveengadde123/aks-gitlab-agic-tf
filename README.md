# AKS GitLab + AGIC Terraform Deployment (Production-Ready)

Deploy GitLab on Azure Kubernetes Service (AKS) with Application Gateway Ingress Controller (AGIC) as the ingress and external PostgreSQL + Redis for high availability.

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│         Azure Resource Group (rg-gitlab)                │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │   Application Gateway (AGIC)                      │   │
│  │   - Public IP: 40.x.x.x (assigns automatically)  │   │
│  │   - Routes traffic to AKS pods                   │   │
│  └──────────────────────────────────────────────────┘   │
│           ↓                                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │   Azure Kubernetes Service (AKS)                  │   │
│  │   - 2 nodes (Standard_D2s_v3)                     │   │
│  │   - GitLab pods deployed in gitlab namespace    │   │
│  └──────────────────────────────────────────────────┘   │
│           ↓                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ PostgreSQL   │  │ Redis Cache  │  │   Storage    │  │
│  │ (External)   │  │  (External)  │  │  Account     │  │
│  │ Port: 5432   │  │ Port: 6379   │  │   (LRS)      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Key Features (Fixed & Production-Ready)

✅ **Application Gateway Integration**: AGIC handles all ingress traffic  
✅ **External PostgreSQL**: Azure Database for PostgreSQL (Flexible Server)  
✅ **External Redis**: Azure Cache for Redis (Basic tier, no SSL required)  
✅ **Proper Secret Management**: Kubernetes secrets for all credentials  
✅ **YAML Validation**: Helm chart compatibility fixes applied  
✅ **Complete Outputs**: Terraform outputs for easy reference  
✅ **Better Logging**: Comprehensive debugging in CI/CD pipeline  
✅ **Proper Ingress Configuration**: AGIC-specific annotations  

## ⚠️ Critical Fixes Applied

### 1. **Redis Configuration** (FIXED)
- **Before**: Used `rediss://` (Redis with SSL) on port 6380
- **After**: Uses `redis://` (plain) on port 6379
- **Reason**: Azure Basic tier Redis doesn't support SSL/TLS
- **File**: `helm/values.yaml`

### 2. **Helm Chart Schema** (FIXED)
- **Before**: Included `certmanager.install: false` causing schema validation error
- **After**: Removed incompatible property (cert-manager already disabled via `configureCertmanager`)
- **File**: `helm/values.yaml`

### 3. **Ingress Configuration** (FIXED)
- **Before**: Duplicate ingress class definitions
- **After**: Clean AGIC annotations with proper protocol settings
- **File**: `k8s/ingress.yaml`

### 4. **Workflow Pipeline** (ENHANCED)
- **Added**: Terraform output parsing to dynamically set values
- **Added**: Better error handling and logging
- **Added**: Pod readiness checks before declaring success
- **Added**: Comprehensive debugging information
- **File**: `.github/workflows/deploy.yaml`

### 5. **Terraform Configuration** (ENHANCED)
- **Added**: AGIC role assignments for proper integration
- **Added**: Comprehensive outputs in `terraform/outputs.tf`
- **Fixed**: PostgreSQL firewall rules for Azure service access
- **File**: `terraform/main.tf`, `terraform/outputs.tf`

## 📁 Project Structure

```
.
├── .github/workflows/
│   └── deploy.yaml                    # GitHub Actions CI/CD Pipeline
├── terraform/
│   ├── main.tf                        # Infrastructure as Code
│   ├── outputs.tf                     # Output values (NEW)
│   └── terraform.tfvars (optional)   # Variable overrides
├── helm/
│   └── values.yaml                    # GitLab Helm Chart Values (FIXED)
├── k8s/
│   └── ingress.yaml                   # Kubernetes Ingress (FIXED)
└── README.md                          # This file
```

## 🚀 Prerequisites

Before deploying, ensure you have:

```bash
# 1. Azure CLI installed and authenticated
az login
az account set --subscription <SUBSCRIPTION_ID>

# 2. Azure Service Principal for GitHub Actions
az ad sp create-for-rbac --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID>

# 3. GitHub Secrets configured (in repository settings)
# - AZURE_CREDENTIALS: Service Principal JSON

# 4. Local tools (optional, for manual testing)
terraform >= 1.0
kubectl >= 1.28
helm >= 3.0
```

## 🎯 Quick Start

### Option 1: Automated Deployment (GitHub Actions)

1. **Push to main branch** triggers the workflow automatically
2. **Monitor** at GitHub Actions tab
3. **Access GitLab** via the public IP (shown in workflow logs)

### Option 2: Manual Deployment

```bash
# 1. Initialize Terraform
cd terraform
terraform init

# 2. Plan deployment
terraform plan -out=tfplan

# 3. Apply infrastructure
terraform apply tfplan

# 4. Get outputs
terraform output

# 5. Configure kubectl
az aks get-credentials \
  --resource-group rg-gitlab \
  --name aks-gitlab-eip \
  --overwrite-existing

# 6. Add GitLab Helm repository
helm repo add gitlab https://charts.gitlab.io
helm repo update

# 7. Get Public IP from Terraform outputs
PUBLIC_IP=$(terraform output -raw app_gateway_public_ip)

# 8. Install GitLab
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --create-namespace \
  -f ../helm/values.yaml \
  --set global.hosts.externalIP=$PUBLIC_IP \
  --timeout 60m \
  --wait

# 9. Apply Ingress configuration
kubectl apply -f ../k8s/ingress.yaml

# 10. Get GitLab root password
kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab \
  -o jsonpath="{.data.password}" | base64 -d
```

## 📊 Accessing GitLab

Once deployed:

1. **Get Public IP**:
   ```bash
   PUBLIC_IP=$(terraform output -raw app_gateway_public_ip)
   echo "GitLab URL: http://$PUBLIC_IP"
   ```

2. **Get Root Password**:
   ```bash
   kubectl get secret gitlab-gitlab-initial-root-password \
     -n gitlab \
     -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Login**:
   - **URL**: `http://<PUBLIC_IP>`
   - **Username**: `root`
   - **Password**: (from command above)

## 🔐 Security Considerations

### Passwords
- **PostgreSQL**: `P@ssw0rd123!Gitlab` (change in `terraform/main.tf`)
- **GitLab Root**: `GitlabRoot@123` (change in `.github/workflows/deploy.yaml`)
- **Redis**: Uses access key from Azure (auto-generated)

### Network Security
- PostgreSQL has firewall rule allowing Azure services
- Redis is accessible within Azure by default
- AGIC manages all ingress traffic

### Recommendations
1. Change default passwords before production
2. Use Azure Key Vault for secrets
3. Enable Azure Firewall for additional protection
4. Use private endpoints for PostgreSQL and Redis
5. Enable SSL/TLS for external access

## 🧪 Verification Steps

```bash
# 1. Check cluster status
kubectl cluster-info
kubectl get nodes

# 2. Check GitLab namespace
kubectl get ns
kubectl get all -n gitlab

# 3. Check pods
kubectl get pods -n gitlab -o wide

# 4. Check services
kubectl get svc -n gitlab

# 5. Check ingress
kubectl get ingress -n gitlab
kubectl describe ingress -n gitlab

# 6. Check logs (if pods are failing)
kubectl logs -n gitlab <pod-name> --all-containers=true --tail=50

# 7. Check PostgreSQL connection
kubectl run psql-test --image=postgres:13 --rm -it -- \
  psql -h gitlab-postgres.postgres.database.azure.com \
  -U gitlabadmin \
  -d gitlabhq_production \
  -c "SELECT version();"

# 8. Check Redis connection
kubectl run redis-test --image=redis:7 --rm -it -- \
  redis-cli -h gitlab-redis-aks-001.redis.cache.windows.net \
  -p 6379 PING
```

## 🐛 Troubleshooting

### Issue: "Helm error: additional properties 'install' not allowed"
**Solution**: This has been fixed. The `certmanager.install` property was removed from `helm/values.yaml`.

### Issue: "Redis connection timeout"
**Solution**: 
- Verify Redis is using port 6379 (not 6380)
- Verify scheme is `redis://` (not `rediss://`)
- Check Azure firewall rules allow AKS to Redis

### Issue: "PostgreSQL connection refused"
**Solution**:
- Verify firewall rule allows Azure services
- Check PostgreSQL server is running
- Verify credentials in secrets match Terraform config

### Issue: "GitLab pods in CrashLoopBackOff"
**Solution**:
- Check pod logs: `kubectl logs <pod-name> -n gitlab`
- Check events: `kubectl describe pod <pod-name> -n gitlab`
- Verify secrets exist: `kubectl get secrets -n gitlab`
- Check resource limits vs pod requests

### Issue: "Ingress not routing traffic"
**Solution**:
- Verify ingress exists: `kubectl get ingress -n gitlab`
- Check AGIC logs: `kubectl logs -n kube-system -l app=ingress-azure`
- Verify service endpoints: `kubectl get endpoints -n gitlab`
- Check Application Gateway backend pools in Azure Portal

## 📈 Monitoring & Logs

### GitHub Actions Logs
- Full deployment logs available in GitHub Actions tab
- Includes terraform plan/apply output
- Helm installation debug logs
- Pod status and logs captured automatically

### Kubernetes Logs
```bash
# GitLab webservice logs
kubectl logs -n gitlab -l app=gitlab-webservice --tail=100 -f

# PostgreSQL connection logs
kubectl logs -n gitlab -l app=gitlab-migrations --tail=100

# Full pod debugging
kubectl describe pod -n gitlab <pod-name>
```

### Azure Resources
- Monitor via Azure Portal
- Check Application Gateway rules in Settings
- Monitor PostgreSQL query performance
- Monitor Redis memory usage

## 🔄 Updating GitLab

```bash
# 1. Update Helm repository
helm repo update

# 2. Perform upgrade
helm upgrade gitlab gitlab/gitlab \
  --namespace gitlab \
  -f helm/values.yaml \
  --timeout 60m

# 3. Verify update
kubectl rollout status deployment/gitlab-webservice-default -n gitlab
```

## 🗑️ Cleanup

```bash
# Delete Helm release
helm uninstall gitlab -n gitlab

# Delete namespace
kubectl delete namespace gitlab

# Destroy all Azure resources
terraform destroy
```

## 📝 Variable Customization

Edit `terraform/main.tf` to customize:

- **PostgreSQL Admin Password**: `variable "postgresql_admin_password"`
- **AKS Node Count**: `default_node_pool { node_count = 2 }`
- **AKS VM Size**: `vm_size = "Standard_D2s_v3"`
- **GitLab Edition**: `global.edition: ce` (community edition) in `helm/values.yaml`
- **Region**: `location = "central india"`

## 📞 Support

For issues related to:
- **GitLab**: https://about.gitlab.com/support/
- **Azure**: https://azure.microsoft.com/support/
- **Terraform**: https://discuss.hashicorp.com/c/terraform/
- **Kubernetes**: https://kubernetes.io/docs/

## 📄 License

This Terraform configuration is provided as-is for GitLab deployment on Azure.

---

## ✅ Verification Checklist

Before going to production:

- [ ] GitHub secrets configured correctly
- [ ] Default passwords changed
- [ ] PostgreSQL and Redis firewall rules reviewed
- [ ] AGIC ingress routes traffic correctly
- [ ] GitLab pods are all running
- [ ] Database migrations completed successfully
- [ ] Backup strategy planned
- [ ] Monitoring and alerting configured
- [ ] SSL/TLS certificate configured (optional)
- [ ] Users and groups created
- [ ] CI/CD runners configured

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