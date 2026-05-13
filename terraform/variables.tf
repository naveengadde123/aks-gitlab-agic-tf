variable "location" {
  default = "East US"
}

variable "resource_group_name" {
  default = "rg-gitlab"
}

variable "aks_name" {
  default = "aks-gitlab-eip"
}
variable "postgres_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}