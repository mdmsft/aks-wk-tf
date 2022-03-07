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
  virtual_network_name = split("/", var.subnet_id)[8]
  virtual_network_id   = join("/", slice(split("/", var.subnet_id), 0, 9))
  azure_defender_cli = jsonencode(
    {
      "location" = "${var.location}"
      "properties" = {
        "securityProfile" = {
          "azureDefender" = {
            "enabled"                         = true
            "logAnalyticsWorkspaceResourceId" = "${var.log_analytics_workspace_id}"
          }
        }
      }
    }
  )
}

resource "azurecaf_name" "azurerm_public_ip" {
  name          = var.workload
  resource_type = "azurerm_public_ip"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_kubernetes_cluster" {
  name          = var.workload
  resource_type = "azurerm_kubernetes_cluster"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_public_ip" "main" {
  name                = azurecaf_name.azurerm_public_ip.result
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  sku_tier            = "Regional"
  allocation_method   = "Static"
  domain_name_label   = "${var.workload}-${var.environment}"

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                      = azurecaf_name.azurerm_kubernetes_cluster.result
  resource_group_name       = var.resource_group_name
  location                  = var.location
  dns_prefix                = var.workload
  automatic_channel_upgrade = "patch"
  kubernetes_version        = var.kubernetes_version
  local_account_disabled    = true
  azure_policy_enabled      = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                         = "sys"
    vm_size                      = "Standard_DS3_v2"
    availability_zones           = [1, 2, 3]
    enable_auto_scaling          = true
    only_critical_addons_enabled = true
    os_disk_size_gb              = 30
    os_disk_type                 = "Ephemeral"
    os_sku                       = "Ubuntu"
    vnet_subnet_id               = var.subnet_id
    max_count                    = 3
    min_count                    = 1
    max_pods                     = 30

    upgrade_settings {
      max_surge = "100%"
    }
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = range(1, 5)
    }

    allowed {
      day   = "Sunday"
      hours = range(1, 5)
    }
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = cidrhost(var.service_cidr, 10)
    docker_bridge_cidr = "192.168.0.1/24"
    service_cidr       = var.service_cidr

    load_balancer_profile {
      outbound_ip_address_ids  = [azurerm_public_ip.main.id]
      outbound_ports_allocated = 4096
    }
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      azure_rbac_enabled = true
      managed            = true
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "linux" {
  name                  = "lnx"
  vm_size               = "Standard_F4s_v2"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  os_disk_size_gb       = 30
  os_disk_type          = "Ephemeral"
  os_sku                = "Ubuntu"
  mode                  = "System"
  vnet_subnet_id        = var.subnet_id
  max_count             = 3
  min_count             = 1
  max_pods              = 30
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id

  upgrade_settings {
    max_surge = "100%"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "windows" {
  name                  = "win"
  vm_size               = "Standard_F4s_v2"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  os_disk_size_gb       = 30
  os_disk_type          = "Ephemeral"
  os_type               = "Windows"
  vnet_subnet_id        = var.subnet_id
  max_count             = 3
  min_count             = 1
  max_pods              = 30
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id

  upgrade_settings {
    max_surge = "100%"
  }
}

resource "azurerm_resource_policy_assignment" "cluster" {
  name                 = "k8s pod security baseline standards for Linux-based workloads"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"
  resource_id          = azurerm_kubernetes_cluster.main.id
  parameters           = <<PARAMETERS
  {
    "effect": {
      "value": "deny"
    }
  }
  PARAMETERS
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  principal_id         = data.azurerm_client_config.main.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.main.id
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  for_each = {
    "Network Contributor"                = var.subnet_id,
    "Storage File Data SMB Share Reader" = var.storage_account_id,
    "Reader"                             = var.storage_account_id,
  }
  scope                = each.value
  role_definition_name = each.key
  principal_id         = azurerm_kubernetes_cluster.main.identity.0.principal_id
}

resource "azurerm_role_assignment" "config_aks_rbac_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.main.object_id
}

resource "null_resource" "azure_defender" {
  depends_on = [
    azurerm_kubernetes_cluster.main
  ]

  provisioner "local-exec" {
    command = "az rest -m put -u /subscriptions/{subscriptionId}/resourcegroups/${var.resource_group_name}/providers/Microsoft.ContainerService/managedClusters/${azurerm_kubernetes_cluster.main.name}?api-version=2021-07-01 -b ${local.azure_defender_cli} -o none"
  }
}
