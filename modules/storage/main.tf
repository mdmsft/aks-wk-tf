terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

data "azurerm_client_config" "main" {
}

locals {
  resource_name         = "file"
  private_dns_zone_name = "privatelink.file.core.windows.net"
}

resource "azurecaf_name" "azurerm_storage_account" {
  name          = var.workload
  resource_type = "azurerm_storage_account"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_storage_account" "main" {
  name                      = azurecaf_name.azurerm_storage_account.result
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_kind              = "FileStorage"
  account_tier              = "Premium"
  account_replication_type  = "ZRS"
  access_tier               = "Hot"
  enable_https_traffic_only = false
  min_tls_version           = "TLS1_2"
  allow_blob_public_access  = false

  network_rules {
    bypass         = ["Logging", "Metrics", "AzureServices"]
    default_action = "Deny"
  }
}

module "dns" {
  source              = "../dns"
  name                = local.private_dns_zone_name
  resource_group_name = var.resource_group_name
  environment         = var.environment
  location            = var.location
  resource_name       = local.resource_name
  subresource_name    = "file"
  resource_id         = azurerm_storage_account.main.id
  subnet_id           = var.private_endpoint_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
}
