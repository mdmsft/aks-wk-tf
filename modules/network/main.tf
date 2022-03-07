terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

resource "azurecaf_name" "azurerm_virtual_network" {
  name          = var.workload
  resource_type = "azurerm_virtual_network"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_subnet" {
  name          = var.workload
  resource_type = "azurerm_subnet"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_subnet_cluster" {
  name          = var.workload
  resource_type = "azurerm_subnet"
  suffixes      = ["aks", var.environment, var.location]
}

resource "azurecaf_name" "azurerm_network_security_group" {
  name          = var.workload
  resource_type = "azurerm_network_security_group"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_network_security_group_cluster" {
  name          = var.workload
  resource_type = "azurerm_network_security_group"
  suffixes      = ["aks", var.environment, var.location]
}

resource "azurerm_virtual_network" "main" {
  name                = azurecaf_name.azurerm_virtual_network.result
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet" "main" {
  name                                           = azurecaf_name.azurerm_subnet.result
  virtual_network_name                           = azurerm_virtual_network.main.name
  resource_group_name                            = azurerm_virtual_network.main.resource_group_name
  address_prefixes                               = [cidrsubnet(var.address_space, 8, 0)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_network_security_group" "main" {
  name                = azurecaf_name.azurerm_network_security_group.result
  location            = var.location
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_subnet" "cluster" {
  name                 = azurecaf_name.azurerm_subnet_cluster.result
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 1)]
}

resource "azurerm_network_security_group" "cluster" {
  name                = azurecaf_name.azurerm_network_security_group_cluster.result
  location            = var.location
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet_network_security_group_association" "cluster" {
  subnet_id                 = azurerm_subnet.cluster.id
  network_security_group_id = azurerm_network_security_group.cluster.id
}