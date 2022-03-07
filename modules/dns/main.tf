terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

resource "azurecaf_name" "azurerm_private_endpoint" {
  name          = var.name
  resource_type = "azurerm_private_endpoint"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_private_endpoint" "main" {
  name                = azurecaf_name.azurerm_private_endpoint.result
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = var.resource_name
    private_connection_resource_id = var.resource_id
    subresource_names              = [var.subresource_name]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = var.name
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
