output "postgres_host" {
  value       = azurerm_postgresql_flexible_server.pg.fqdn
  description = "PostgreSQL Flexible Server FQDN"
}

output "redis_host" {
  value       = azurerm_redis_cache.redis.hostname
  description = "Redis hostname"
}

output "redis_key" {
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
  description = "Redis primary access key"
}

output "storage_account" {
  value       = azurerm_storage_account.storage.name
  description = "Storage account name"
}

output "storage_key" {
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
  description = "Storage account key"
}