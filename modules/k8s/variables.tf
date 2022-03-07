variable "cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "context_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_access_key" {
  type      = string
  sensitive = true
}
