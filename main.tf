terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.97.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.13"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
    key              = "wk"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = local.context_name
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
  use_msal            = true
  subscription_id     = "6f3a143b-51cc-4a89-aa5a-3c98bb3f5e46"
}

provider "azurecaf" {
}

locals {
  private_dns_zones = {
    storage = "privatelink.file.core.windows.net"
  }
  context_name = "${var.workload}-${var.environment}"
}

data "azurerm_client_config" "current" {
}

resource "azurecaf_name" "resource_group" {
  name          = var.workload
  resource_type = "azurerm_resource_group"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    workload    = var.workload
    environment = var.environment
    location    = var.location
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_zone" "main" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name

  lifecycle {
    ignore_changes = [tags]
  }
}

module "network" {
  source              = "./modules/network"
  workload            = var.workload
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = local.private_dns_zones
  name                  = each.value
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value
  virtual_network_id    = module.network.id
}

module "monitor" {
  source              = "./modules/monitor"
  workload            = var.workload
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

module "storage" {
  source                     = "./modules/storage"
  workload                   = var.workload
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  private_endpoint_subnet_id = module.network.subnet_id
  private_dns_zone_id        = azurerm_private_dns_zone.main["storage"].id
}

module "cluster" {
  source                     = "./modules/cluster"
  workload                   = var.workload
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = module.monitor.id
  subnet_id                  = module.network.cluster_subnet_id
  storage_account_id         = module.storage.id
}

module "k8s" {
  depends_on = [
    module.cluster
  ]
  source               = "./modules/k8s"
  cluster_name         = module.cluster.name
  resource_group_name  = azurerm_resource_group.main.name
  context_name         = local.context_name
  storage_account_name = module.storage.account_name
  storage_access_key   = module.storage.access_key
}
