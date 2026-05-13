# 🏗️ Complete Architecture & File Structure Guide

## 📋 Table of Contents
1. [Overall Architecture](#overall-architecture)
2. [File Organization](#file-organization)
3. [File Dependencies](#file-dependencies)
4. [How Everything Works Together](#how-everything-works-together)
5. [Data Flow](#data-flow)
6. [Deployment Flow](#deployment-flow)

---

## 🎯 Overall Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET / USERS                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ↓ HTTP Traffic (Port 80)
                    ┌────────────────────┐
                    │  Application       │
                    │  Gateway (AGIC)    │
                    │  Public IP: 40.x   │
                    └────────┬───────────┘
                             │
                             ↓
                    ┌────────────────────────────────┐
                    │   Azure Kubernetes Service     │
                    │   (AKS Cluster)                │
                    │   - 2 Nodes (Standard_D2s_v3)  │
                    │   - gitlab namespace           │
                    └────────┬──────────┬─────────────┘
                             │          │
                ┌────────────┘          └──────────────┐
                ↓                                      ↓
        ┌──────────────┐  ┌────────────┐  ┌──────────────────┐
        │   GitLab     │  │  Gitaly    │  │  Other Services  │
        │  Webservice  │  │ (Git Repo) │  │ (Sidekiq, etc)   │
        │   Pods       │  │   Pods     │  │      Pods        │
        └──────┬───────┘  └─────┬──────┘  └────────┬─────────┘
               │                 │                   │
        ┌──────┴─────────────────┴───────────────────┴─────────┐
        │                                                       │
        ↓                      ↓                       ↓
    ┌────────────┐       ┌──────────────┐      ┌────────────┐
    │PostgreSQL  │       │ Redis Cache  │      │  Storage   │
    │ (External) │       │  (External)  │      │  Account   │
    │Port: 5432  │       │ Port: 6379   │      │ (Backups)  │
    └────────────┘       └──────────────┘      └────────────┘
```

### Component Breakdown

| Component | Purpose | External? | Why? |
|-----------|---------|-----------|------|
| **Application Gateway** | Routes internet traffic to AKS pods | No (in VNET) | Ingress controller |
| **AKS Cluster** | Runs GitLab containerized | No (managed by Azure) | Container orchestration |
| **PostgreSQL** | Stores GitLab data | Yes | For scalability & HA |
| **Redis** | Caches & sessions | Yes | For performance |
| **Storage Account** | Backup & artifacts | Yes | Cheap long-term storage |

---

## 📁 File Organization

```
aks-gitlab-agic-tf/
│
├── 📄 README.md                          # Project overview
├── 📄 CONFIGURATION_SUMMARY.md           # Detailed configuration guide
│
├── 📁 terraform/                         # Infrastructure as Code
│   ├── main.tf                           # Resource definitions
│   ├── variables.tf                      # Input variables
│   ├── outputs.tf                        # Output values
│   ├── terraform.tfvars.example          # Example configuration
│   ├── .gitignore                        # Terraform ignore rules
│   └── README.md                         # Terraform-specific guide
│
├── 📁 helm/                              # Kubernetes application config
│   └── values.yaml                       # GitLab Helm chart values
│
├── 📁 k8s/                               # Kubernetes manifests
│   └── ingress.yaml                      # Ingress routing config
│
└── 📁 .github/workflows/                 # CI/CD automation
    └── deploy.yaml                       # GitHub Actions pipeline
```

---

## 🔗 File Dependencies & Relationships

### Dependency Graph

```
                    ┌──────────────────┐
                    │ GitHub Secrets   │
                    │(AZURE_CREDENTIALS)
                    └────────┬─────────┘
                             │
                             ↓
┌────────────────────────────────────────────────┐
│  .github/workflows/deploy.yaml                 │
│  (GitHub Actions - Orchestrator)               │
│  ├─ Triggers: push to main branch              │
│  └─ Runs all deployment steps                  │
└────────────────────┬───────────────────────────┘
                     │
        ┌────────────┴────────────┬──────────────┐
        ↓                         ↓              ↓
   ┌─────────────┐      ┌──────────────┐  ┌─────────────┐
   │ Terraform   │      │  Kubernetes  │  │    Helm     │
   │  Execution  │      │   Execution  │  │ Execution   │
   └──────┬──────┘      └──────┬───────┘  └──────┬──────┘
          │                    │                  │
          ↓                    ↓                  ↓
   ┌─────────────────┐  ┌─────────────────┐ ┌──────────────┐
   │ terraform/      │  │ kubernetes/     │ │ helm/        │
   │ main.tf ────────┼─→ k8s/ingress.yaml │ │ values.yaml  │
   │ variables.tf    │  └─────────────────┘ └──────────────┘
   │ outputs.tf      │
   └─────────────────┘

        Uses      Defines Output
         ↓             ↓
   ┌──────────────────────────────────┐
   │ terraform.tfvars                 │
   │ (Environment-specific values)     │
   └──────────────────────────────────┘
```

### File Connection Matrix

| File | Depends On | Provides | Used By |
|------|-----------|----------|---------|
| **variables.tf** | None | Variable definitions | main.tf, terraform.tfvars |
| **main.tf** | variables.tf | Infrastructure resources | outputs.tf, k8s/ingress.yaml |
| **outputs.tf** | main.tf | Resource references | deploy.yaml workflow |
| **terraform.tfvars** | variables.tf | Variable values | terraform apply |
| **values.yaml** | outputs.tf | GitLab config | Helm install |
| **k8s/ingress.yaml** | main.tf | Ingress rules | kubectl apply |
| **deploy.yaml** | all above | Orchestration | GitHub Actions |

---

## 🔄 How Everything Works Together

### 1️⃣ **Terraform Layer** (Infrastructure Creation)

```
terraform/
├── variables.tf        ← Defines: "What can be configured?"
│   Example: aks_node_count, postgresql_sku_name
│
├── terraform.tfvars    ← Specifies: "What values do we use?"
│   Example: aks_node_count = 2
│
├── main.tf            ← Creates: "Azure resources using variables"
│   ┌─ Resource Group
│   ├─ Virtual Network + Subnets
│   ├─ AKS Cluster (uses var.aks_node_count)
│   ├─ Application Gateway (uses var.app_gateway_sku_name)
│   ├─ PostgreSQL (uses var.postgresql_sku_name)
│   ├─ Redis (uses var.redis_capacity)
│   └─ Storage Account
│
└── outputs.tf         ← Exports: "What values can others use?"
    ├─ app_gateway_public_ip  ← Public URL for GitLab
    ├─ postgresql_fqdn        ← Database hostname
    ├─ redis_hostname         ← Cache hostname
    └─ aks_cluster_name       ← Cluster name for kubectl
```

**Example Workflow**:
```
terraform init
  ↓
terraform plan (uses variables.tf + terraform.tfvars)
  ↓
terraform apply (creates infrastructure)
  ↓
Resources created in Azure
  ↓
Outputs generated (from outputs.tf)
  ↓
Other tools read outputs
```

### 2️⃣ **Kubernetes Layer** (Container Orchestration)

```
AKS Cluster (created by Terraform)
│
├─ Kubernetes Namespace "gitlab"
│   │
│   ├─ GitLab Webservice Pods
│   │  └─ Reads: PostgreSQL host, Redis host (from Secrets)
│   │
│   ├─ Gitaly Pods (Git backend)
│   │
│   ├─ Services (expose pods internally)
│   │
│   └─ Ingress (k8s/ingress.yaml)
│      └─ Routes traffic via AGIC to webservice
│
└─ Secrets (created by deploy.yaml)
   ├─ gitlab-postgres-secret       ← Database password
   ├─ gitlab-redis-secret          ← Redis password
   ├─ gitlab-storage-secret        ← Storage credentials
   └─ gitlab-gitlab-initial-root-password  ← Root password
```

### 3️⃣ **Helm Layer** (GitLab Configuration)

```
helm/values.yaml
│
├─ Global Settings
│  ├─ hosts.domain = "nip.io"
│  ├─ hosts.externalIP = "$PUBLIC_IP"
│  └─ edition = "ce" (Community)
│
├─ PostgreSQL Settings
│  ├─ psql.host = $POSTGRES_HOST (from Terraform output)
│  ├─ psql.password.secret = gitlab-postgres-secret
│  └─ psql.install = false (use external)
│
├─ Redis Settings
│  ├─ redis.host = $REDIS_HOST (from Terraform output)
│  ├─ redis.port = 6379
│  └─ redis.install = false (use external)
│
└─ Component toggles
   ├─ nginx-ingress.enabled = false (AGIC handles it)
   ├─ postgresql.install = false (external)
   ├─ redis.install = false (external)
   ├─ prometheus.install = false
   └─ registry.enabled = false
```

### 4️⃣ **Ingress Layer** (Traffic Routing)

```
k8s/ingress.yaml
│
├─ ingressClassName: azure-application-gateway
│
├─ Rules
│  └─ Host: gitlab.nip.io
│     └─ Path: /
│        └─ Backend Service: gitlab-webservice-default
│           └─ Port: 8181
│
└─ AGIC receives this config
   ├─ Reads: Application Gateway resource
   ├─ Creates: Backend pools
   ├─ Sets up: HTTP listeners
   └─ Routes: Internet → AppGW → AKS → GitLab Pods
```

---

## 📊 Data Flow

### Request Flow: User to GitLab

```
1. User enters URL
   └─ http://40.x.x.x (Public IP from AppGW)
   
2. DNS resolves to Public IP
   └─ Application Gateway receives request
   
3. AGIC (running in AKS) configured AppGW with rules
   └─ AppGW knows to route to "gitlab-webservice-default"
   
4. AppGW routes to AKS pod
   └─ gitlab-webservice-default pod processes request
   
5. GitLab pod connects to PostgreSQL
   └─ Uses secret: gitlab-postgres-secret
   └─ Connects to: postgresql_host (from Terraform)
   
6. GitLab pod connects to Redis
   └─ Uses secret: gitlab-redis-secret
   └─ Connects to: redis_hostname (from Terraform)
   
7. Response sent back through same path
   └─ GitLab Pod → AppGW → User's Browser
```

### Configuration Data Flow

```
Terraform Creates Infrastructure
   ↓
Terraform outputs values
   ├─ public_ip: 40.x.x.x
   ├─ postgresql_fqdn: gitlab-postgres-xxx.postgres.database.azure.com
   └─ redis_hostname: gitlab-redis-aks-xxx.redis.cache.windows.net
   ↓
GitHub Actions reads outputs
   ├─ Sets environment variables
   ├─ Passes to Helm
   └─ Passes to kubectl
   ↓
Helm values.yaml uses these
   ├─ Sets global.hosts.externalIP = $PUBLIC_IP
   ├─ Sets global.psql.host = $POSTGRESQL_FQDN
   └─ Sets global.redis.host = $REDIS_HOSTNAME
   ↓
GitLab pods use values
   ├─ Connect to PostgreSQL at the host
   ├─ Connect to Redis at the host
   └─ Serve on externalIP
```

---

## 🚀 Deployment Flow

### Step-by-Step Execution

```
1. GitHub Actions Triggered
   └─ Commit pushed to main branch
   
2. Terraform Init
   └─ terraform/main.tf + variables.tf loaded
   
3. Terraform Plan
   └─ Reads: terraform.tfvars values
   └─ Generates: infrastructure plan
   
4. Terraform Apply
   ├─ Creates: Resource Group, VNet, Subnets
   ├─ Creates: AKS Cluster (2 nodes)
   ├─ Creates: Application Gateway + Public IP
   ├─ Creates: PostgreSQL Server + Database
   ├─ Creates: Redis Cache
   ├─ Creates: Storage Account
   └─ Waits: ~10-15 minutes
   
5. Terraform Outputs Exported
   ├─ app_gateway_public_ip = 40.x.x.x
   ├─ postgresql_fqdn = gitlab-postgres-xxx...
   ├─ redis_hostname = gitlab-redis-aks-xxx...
   └─ Written to: $GITHUB_ENV (environment variables)
   
6. Get AKS Credentials
   └─ kubectl configured to access cluster
   
7. Create Secrets in Kubernetes
   ├─ gitlab-postgres-secret (password: P@ssw0rd123!Gitlab)
   ├─ gitlab-redis-secret (password: auto-generated key)
   ├─ gitlab-storage-secret (connection string)
   └─ gitlab-gitlab-initial-root-password (GitlabRoot@123)
   
8. Add GitLab Helm Repository
   └─ helm repo add gitlab https://charts.gitlab.io
   
9. Install GitLab via Helm
   ├─ Uses: helm/values.yaml
   ├─ Substitutes: Public IP, Postgres host, Redis host
   ├─ Creates: Pods for webservice, gitaly, etc
   ├─ Creates: Services
   ├─ Waits: ~5-10 minutes for pods ready
   └─ Status: All running
   
10. Apply Ingress Configuration
    ├─ kubectl apply -f k8s/ingress.yaml
    ├─ AGIC picks up ingress config
    ├─ Updates: Application Gateway rules
    └─ Traffic now flows to GitLab
    
11. Verification & Output
    ├─ All pods running
    ├─ Services accessible
    ├─ Ingress configured
    └─ GitLab accessible at: http://40.x.x.x
```

---

## 🔐 Secret Management Flow

```
Passwords Defined
├─ PostgreSQL: P@ssw0rd123!Gitlab      (in terraform/variables.tf)
├─ GitLab Root: GitlabRoot@123         (in deploy.yaml)
└─ Redis: Auto-generated by Azure

GitHub Actions workflow
├─ Retrieves PostgreSQL password from terraform.tfvars
├─ Retrieves Redis key using: az redis list-keys
├─ Creates Kubernetes Secrets:
│  ├─ kubectl create secret gitlab-postgres-secret
│  ├─ kubectl create secret gitlab-redis-secret
│  └─ kubectl create secret gitlab-gitlab-initial-root-password
│
GitLab Helm Chart
├─ References: secret: gitlab-postgres-secret
├─ References: secret: gitlab-redis-secret
├─ GitLab pods mount these secrets as environment variables
│
GitLab Application
└─ Reads environment variables
   ├─ Connects to PostgreSQL using password from secret
   ├─ Connects to Redis using password from secret
   └─ Application works seamlessly
```

---

## 🔄 Variable Flow

```
terraform/variables.tf
│
├─ Defines: 40+ variables
│  ├─ azure_region (default: "central india")
│  ├─ aks_node_count (default: 2)
│  ├─ postgresql_sku_name (default: "B_Standard_B1ms")
│  ├─ redis_capacity (default: 1)
│  └─ ... and more
│
terraform/terraform.tfvars.example
│
├─ Shows example values
│  ├─ Copy to: terraform.tfvars
│  └─ Customize as needed
│
terraform/terraform.tfvars (NOT IN GIT)
│
├─ Your actual values
│  ├─ aks_node_count = 3 (instead of default 2)
│  ├─ postgresql_sku_name = "D_Standard_D4s_v3" (for production)
│  └─ ... your customizations
│
terraform apply
│
├─ Reads: variables.tf (definitions)
├─ Reads: terraform.tfvars (your values)
├─ Creates: Resources with your values
└─ Output: New infrastructure
```

---

## 🎯 Why This Architecture?

### Benefits of This Design

| Aspect | Benefit |
|--------|---------|
| **Terraform** | Infrastructure as Code, version controlled, repeatable |
| **Variables** | Parameterized, reusable, environment-specific configs |
| **External DB/Cache** | Scalability, high availability, independent backup |
| **AKS + AGIC** | Managed Kubernetes, automatic ingress management |
| **Helm** | Package management, easy updates, templated configs |
| **GitHub Actions** | CI/CD automation, no manual steps |
| **Secrets** | Secure credential management, not in code |

### Scalability Example

```
Current: 2 AKS nodes, 1GB Redis, 1GB PostgreSQL

To scale up: Just change variables
├─ aks_node_count = 5
├─ redis_capacity = 6
├─ postgresql_sku_name = "D_Standard_D4s_v3"

Then:
├─ terraform plan
├─ terraform apply
└─ Infrastructure scaled up automatically!
```

---

## 📞 Quick Reference

### To Get Public URL
```bash
terraform output app_gateway_public_ip
# Output: 40.x.x.x
# URL: http://40.x.x.x
```

### To Get Database Host
```bash
terraform output postgresql_fqdn
# Output: gitlab-postgres-xxx.postgres.database.azure.com
```

### To Get Root Password
```bash
kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab \
  -o jsonpath="{.data.password}" | base64 -d
# Output: GitlabRoot@123
```

### To Add More Nodes
```yaml
# Edit: terraform.tfvars
aks_node_count = 3  # Change from 2 to 3

# Then:
terraform plan
terraform apply
```

### To Update GitLab
```bash
helm repo update
helm upgrade gitlab gitlab/gitlab -n gitlab -f helm/values.yaml
```

---

## 🏗️ Component Responsibilities

| Component | Responsibility |
|-----------|-----------------|
| **terraform/main.tf** | Define all Azure resources |
| **terraform/variables.tf** | Define what can be configured |
| **terraform/outputs.tf** | Export resource details for others |
| **terraform/terraform.tfvars** | Specify YOUR configuration |
| **helm/values.yaml** | Configure GitLab application |
| **k8s/ingress.yaml** | Configure traffic routing |
| **.github/workflows/deploy.yaml** | Orchestrate entire deployment |

---

## ✅ Summary

This architecture provides:
- ✅ **Infrastructure as Code** (Terraform)
- ✅ **Parameterized Configuration** (variables)
- ✅ **Containerized Application** (Docker + Kubernetes)
- ✅ **Scalable Databases** (External PostgreSQL + Redis)
- ✅ **Automatic Routing** (AGIC)
- ✅ **Automated Deployment** (GitHub Actions)
- ✅ **Secure Secrets** (Kubernetes Secrets)

All files work together seamlessly to provide a **production-ready, scalable GitLab deployment on Azure!**

---

**Last Updated**: May 13, 2026
