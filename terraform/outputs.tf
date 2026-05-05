output "postgres_host" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "redis_host" {
  value = azurerm_redis_cache.redis.hostname
}

output "redis_key" {
  value     = azurerm_redis_cache.redis.primary_access_key
  sensitive = true
}

output "storage_account" {
  value = azurerm_storage_account.storage.name
}

output "storage_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}