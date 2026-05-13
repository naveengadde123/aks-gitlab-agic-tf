variable "location" {
  description = "Azure Region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Azure Resource Group Name"
  type        = string
  default     = "rg-gitlab"
}

variable "aks_name" {
  description = "AKS Cluster Name"
  type        = string
  default     = "aks-gitlab-eip"
}

variable "postgres_admin_username" {
  description = "PostgreSQL Admin Username"
  type        = string
  default     = "gitlabadmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL Admin Password"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!Gitlab"
}