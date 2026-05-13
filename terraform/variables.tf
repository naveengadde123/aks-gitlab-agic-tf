# =====================================
# Terraform Input Variables
# =====================================

# -------------------------
# Azure Configuration
# -------------------------
variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "central india"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-gitlab"
}

# -------------------------
# Virtual Network Configuration
# -------------------------
variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
  default     = "aks-vnet"
}

variable "vnet_address_space" {
  description = "Virtual Network address space"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "aks_subnet_name" {
  description = "AKS Subnet name"
  type        = string
  default     = "aks-subnet"
}

variable "aks_subnet_prefix" {
  description = "AKS Subnet address prefix"
  type        = list(string)
  default     = ["10.240.0.0/16"]
}

variable "appgw_subnet_name" {
  description = "Application Gateway Subnet name"
  type        = string
  default     = "appgw-subnet"
}

variable "appgw_subnet_prefix" {
  description = "Application Gateway Subnet address prefix"
  type        = list(string)
  default     = ["10.241.0.0/16"]
}

# -------------------------
# AKS Cluster Configuration
# -------------------------
variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-gitlab-eip"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "gitlabaks"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 2
  
  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 10
    error_message = "AKS node count must be between 1 and 10."
  }
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
  
  validation {
    condition     = can(regex("Standard_", var.aks_vm_size))
    error_message = "AKS VM size must be a valid Azure VM type (Standard_*)."
  }
}

variable "aks_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "agentpool"
}

# -------------------------
# Application Gateway Configuration
# -------------------------
variable "app_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
  default     = "gitlab-appgw"
}

variable "app_gateway_sku_name" {
  description = "Application Gateway SKU name"
  type        = string
  default     = "Standard_v2"
  
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.app_gateway_sku_name)
    error_message = "Application Gateway SKU must be Standard_v2 or WAF_v2."
  }
}

variable "app_gateway_sku_tier" {
  description = "Application Gateway SKU tier"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  description = "Application Gateway capacity (auto-scales 1-125)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.app_gateway_capacity >= 1 && var.app_gateway_capacity <= 125
    error_message = "Application Gateway capacity must be between 1 and 125."
  }
}

variable "app_gateway_pip_name" {
  description = "Public IP name for Application Gateway"
  type        = string
  default     = "appgw-pip"
}

# -------------------------
# PostgreSQL Configuration
# -------------------------
variable "postgresql_server_name_prefix" {
  description = "PostgreSQL server name prefix (suffix will be added)"
  type        = string
  default     = "gitlab-postgres"
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "13"
  
  validation {
    condition     = contains(["11", "12", "13", "14", "15"], var.postgresql_version)
    error_message = "PostgreSQL version must be 11, 12, 13, 14, or 15."
  }
}

variable "postgresql_admin_login" {
  description = "PostgreSQL administrator login"
  type        = string
  default     = "gitlabadmin"
  
  validation {
    condition     = length(var.postgresql_admin_login) >= 1 && length(var.postgresql_admin_login) <= 63
    error_message = "PostgreSQL admin login must be 1-63 characters."
  }
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!Gitlab"
  
  validation {
    condition     = length(var.postgresql_admin_password) >= 8
    error_message = "PostgreSQL password must be at least 8 characters."
  }
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
  
  validation {
    condition     = var.postgresql_storage_mb >= 32768 && var.postgresql_storage_mb <= 2097152
    error_message = "PostgreSQL storage must be between 32GB and 2TB."
  }
}

variable "postgresql_sku_name" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "B_Standard_B1ms"
  
  validation {
    condition     = can(regex("^(B|D|E)_", var.postgresql_sku_name))
    error_message = "PostgreSQL SKU must be valid (B_*, D_*, E_*)."
  }
}

variable "postgresql_database_name" {
  description = "PostgreSQL database name for GitLab"
  type        = string
  default     = "gitlabhq_production"
}

variable "postgresql_database_charset" {
  description = "PostgreSQL database charset"
  type        = string
  default     = "UTF8"
}

variable "postgresql_database_collation" {
  description = "PostgreSQL database collation"
  type        = string
  default     = "en_US.utf8"
}

# -------------------------
# Redis Configuration
# -------------------------
variable "redis_name_prefix" {
  description = "Redis cache name prefix (suffix will be added)"
  type        = string
  default     = "gitlab-redis-aks"
}

variable "redis_capacity" {
  description = "Redis cache capacity (GB)"
  type        = number
  default     = 1
  
  validation {
    condition     = contains([0.25, 0.5, 1, 2, 4, 6, 13, 26, 53], var.redis_capacity)
    error_message = "Redis capacity must be valid (0.25, 0.5, 1, 2, 4, 6, 13, 26, 53 GB)."
  }
}

variable "redis_family" {
  description = "Redis cache family (C=Basic, P=Premium)"
  type        = string
  default     = "C"
  
  validation {
    condition     = contains(["C", "P"], var.redis_family)
    error_message = "Redis family must be C (Basic) or P (Premium)."
  }
}

variable "redis_sku_name" {
  description = "Redis SKU name"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.redis_sku_name)
    error_message = "Redis SKU must be Basic, Standard, or Premium."
  }
}

variable "redis_enable_non_ssl_port" {
  description = "Enable non-SSL port for Redis (6379)"
  type        = bool
  default     = true
}

# -------------------------
# Storage Account Configuration
# -------------------------
variable "storage_account_name_prefix" {
  description = "Storage account name prefix (suffix will be added)"
  type        = string
  default     = "gitlabsa"
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Storage account replication type must be valid (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)."
  }
}

# -------------------------
# GitLab Kubernetes Configuration
# -------------------------
variable "gitlab_namespace" {
  description = "Kubernetes namespace for GitLab"
  type        = string
  default     = "gitlab"
}

variable "gitlab_edition" {
  description = "GitLab edition (ce=Community, ee=Enterprise)"
  type        = string
  default     = "ce"
  
  validation {
    condition     = contains(["ce", "ee"], var.gitlab_edition)
    error_message = "GitLab edition must be 'ce' (Community) or 'ee' (Enterprise)."
  }
}

variable "gitlab_root_password" {
  description = "GitLab root user password"
  type        = string
  sensitive   = true
  default     = "GitlabRoot@123"
  
  validation {
    condition     = length(var.gitlab_root_password) >= 8
    error_message = "GitLab root password must be at least 8 characters."
  }
}

# -------------------------
# Tags and Naming
# -------------------------
variable "environment_tags" {
  description = "Environment tags for all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "GitLab"
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-05-13"
  }
}

variable "enable_resource_tags" {
  description = "Enable resource tagging"
  type        = bool
  default     = true
}
