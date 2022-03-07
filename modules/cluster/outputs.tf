output "kubelet_identity" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
}

output "identity" {
  value = azurerm_kubernetes_cluster.main.identity.0.principal_id
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.main.node_resource_group
}

output "id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "public_ip_id" {
  value = azurerm_public_ip.main.id
}
