output "id" {
  value = azurerm_virtual_network.main.id
}

output "name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_id" {
  value = azurerm_subnet.main.id
}

output "cluster_subnet_id" {
  value = azurerm_subnet.cluster.id
}