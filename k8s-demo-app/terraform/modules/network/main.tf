resource "azurerm_virtual_network" "aks" {
  name                = "vnet-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  tags = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-${var.environment}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = var.subnet_prefix

  service_endpoints = ["Microsoft.ContainerRegistry"]
}
