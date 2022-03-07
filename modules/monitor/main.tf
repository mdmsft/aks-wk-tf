terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

resource "azurecaf_name" "azurerm_log_analytics_workspace" {
  name          = var.workload
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = azurecaf_name.azurerm_log_analytics_workspace.result
  resource_group_name = var.resource_group_name
  location            = var.location
  retention_in_days   = 30
  daily_quota_gb      = 1

  lifecycle {
    ignore_changes = [tags]
  }
}
