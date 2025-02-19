terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                 = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment}-aks"
  location = var.location
  tags     = var.tags
}

module "network" {
  source              = "../../modules/network"
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
  subnet_prefix       = var.subnet_prefix
  tags                = var.tags
}

module "acr" {
  source              = "../../modules/acr"
  acr_name            = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags
}

module "aks" {
  source              = "../../modules/aks"
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  node_vm_size        = var.node_vm_size
  subnet_id           = module.network.subnet_id
  min_node_count      = var.min_node_count
  max_node_count      = var.max_node_count
  acr_id              = module.acr.acr_id
  tags                = var.tags
}
