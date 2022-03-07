variable "workload" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.22.6"
}

variable "service_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "storage_account_id" {
  type = string
}