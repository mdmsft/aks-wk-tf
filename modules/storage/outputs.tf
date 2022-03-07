output "account_name" {
  value = azurerm_storage_account.main.name
}

output "access_key" {
  value = azurerm_storage_account.main.primary_access_key
}

output "id" {
  value = azurerm_storage_account.main.id
}
