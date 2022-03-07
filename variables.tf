variable "workload" {
  type    = string
  default = "wk"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "address_space" {
  type    = string
  default = "172.17.0.0/16"
}
