terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "random" {}

# Random suffix for globally unique resource names
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# -------------------------
# Resource Group
# -------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.azure_region
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# -------------------------
# Virtual Network
# -------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# -------------------------
# Subnets
# -------------------------
resource "azurerm_subnet" "aks_subnet" {
  name                 = var.aks_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.aks_subnet_prefix
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = var.appgw_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.appgw_subnet_prefix
}

# -------------------------
# Public IP for App Gateway
# -------------------------
resource "azurerm_public_ip" "appgw_pip" {
  name                = var.app_gateway_pip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# -------------------------
# Application Gateway (FIXED)
# -------------------------
resource "azurerm_application_gateway" "appgw" {
  name                = var.app_gateway_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = var.app_gateway_sku_name
    tier     = var.app_gateway_sku_tier
    capacity = var.app_gateway_capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  backend_address_pool {
    name = "dummy-backend"
  }

  backend_http_settings {
    name                  = "http-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "dummy-backend"
    backend_http_settings_name = "http-setting"
    priority                   = 1
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# -------------------------
# AKS Cluster with AGIC
# -------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_dns_prefix

  default_node_pool {
    name           = var.aks_node_pool_name
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.appgw.id
  }
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# -------------------------
# PostgreSQL (ADDED)
# -------------------------
resource "azurerm_postgresql_flexible_server" "pg" {
  name                   = "${var.postgresql_server_name_prefix}-${random_string.storage_suffix.result}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = var.postgresql_version

  administrator_login    = var.postgresql_admin_login
  administrator_password = var.postgresql_admin_password

  storage_mb = var.postgresql_storage_mb
  sku_name   = var.postgresql_sku_name

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_vnet_link]
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "gitlab_db" {
  name       = var.postgresql_database_name
  server_id  = azurerm_postgresql_flexible_server.pg.id
  charset    = var.postgresql_database_charset
  collation  = var.postgresql_database_collation
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_vnet_link" {
  name                  = "postgres-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# -------------------------
# Redis (ADDED)
# -------------------------
resource "azurerm_redis_cache" "redis" {
  name                = "${var.redis_name_prefix}-${random_string.storage_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku_name
  enable_non_ssl_port = var.redis_enable_non_ssl_port
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# -------------------------
# Storage Account (ADDED)
# -------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "${var.storage_account_name_prefix}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  
  tags = var.enable_resource_tags ? var.environment_tags : {}
}

# -------------------------
# AGIC Role Assignments
# -------------------------
resource "azurerm_role_assignment" "agic_reader" {
  scope              = azurerm_application_gateway.appgw.id
  role_definition_name = "Reader"
  principal_id       = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "agic_contributor" {
  scope              = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id       = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].identity[0].principal_id
}

# -------------------------
# AGIC Role Assignments
# -------------------------
resource "azurerm_role_assignment" "agic_reader" {
  scope              = azurerm_application_gateway.appgw.id
  role_definition_name = "Reader"
  principal_id       = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "agic_contributor" {
  scope              = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id       = azurerm_kubernetes_cluster.aks.ingress_application_gateway[0].identity[0].principal_id
}
