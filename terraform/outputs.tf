output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "postgres_host" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "redis_host" {
  value = azurerm_redis_cache.redis.hostname
}