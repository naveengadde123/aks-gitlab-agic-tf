# =====================================
# Terraform Outputs
# =====================================

# AKS Cluster Outputs
output "aks_cluster_id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "AKS Cluster ID"
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "AKS Cluster Name"
}

output "aks_cluster_fqdn" {
  value       = azurerm_kubernetes_cluster.aks.fqdn
  description = "AKS Cluster FQDN"
}

# Application Gateway Outputs
output "app_gateway_public_ip" {
  value       = azurerm_public_ip.appgw_pip.ip_address
  description = "Application Gateway Public IP Address"
}

output "app_gateway_id" {
  value       = azurerm_application_gateway.appgw.id
  description = "Application Gateway Resource ID"
}

# PostgreSQL Outputs
output "postgresql_fqdn" {
  value       = azurerm_postgresql_flexible_server.pg.fqdn
  description = "PostgreSQL Fully Qualified Domain Name"
  sensitive   = true
}

output "postgresql_id" {
  value       = azurerm_postgresql_flexible_server.pg.id
  description = "PostgreSQL Server ID"
}

output "postgresql_username" {
  value       = azurerm_postgresql_flexible_server.pg.administrator_login
  description = "PostgreSQL Administrator Username"
}

output "postgresql_database_name" {
  value       = azurerm_postgresql_flexible_server_database.gitlab_db.name
  description = "GitLab Database Name"
}

# Redis Outputs
output "redis_hostname" {
  value       = azurerm_redis_cache.redis.hostname
  description = "Redis Cache Hostname"
}

output "redis_id" {
  value       = azurerm_redis_cache.redis.id
  description = "Redis Cache ID"
}

output "redis_port" {
  value       = azurerm_redis_cache.redis.port
  description = "Redis Cache Port (6379 for Basic tier, no SSL)"
}

# Storage Account Outputs
output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Storage Account Name"
}

output "storage_account_id" {
  value       = azurerm_storage_account.storage.id
  description = "Storage Account ID"
}

# Resource Group Output
output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group Name"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "Resource Group ID"
}

# Network Outputs
output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "Virtual Network ID"
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks_subnet.id
  description = "AKS Subnet ID"
}

output "appgw_subnet_id" {
  value       = azurerm_subnet.appgw_subnet.id
  description = "Application Gateway Subnet ID"
}

# GitLab Access Information
output "gitlab_access_url" {
  value       = "http://${azurerm_public_ip.appgw_pip.ip_address}"
  description = "GitLab Access URL via Application Gateway Public IP"
}

output "gitlab_root_username" {
  value       = "root"
  description = "GitLab Root Username"
}

output "gitlab_root_password_secret" {
  value       = "gitlab-gitlab-initial-root-password"
  description = "Kubernetes secret name containing GitLab root password"
}
