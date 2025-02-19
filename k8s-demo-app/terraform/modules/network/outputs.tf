output "subnet_id" {
  value = azurerm_subnet.aks.id
}

output "vnet_name" {
  value = azurerm_virtual_network.aks.name
}
