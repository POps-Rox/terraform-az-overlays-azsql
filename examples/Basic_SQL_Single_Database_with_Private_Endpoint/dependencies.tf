# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#---------------------------------------------------------
# Azure Region Lookup
#----------------------------------------------------------
module "mod_azure_region_lookup" {
  source = "github.com/POps-Rox/terraform-az-overlays-azregionslookup"

  azure_region = "eastus"
}

resource "azurerm_resource_group" "sql-rg" {
  name     = "sql-service-rg"
  location = module.mod_azure_region_lookup.location_cli
  tags = {
    environment = "test"
  }
}

resource "azurerm_virtual_network" "sql-vnet" {
  depends_on = [
    azurerm_resource_group.sql-rg
  ]
  name                = "sql-service-network"
  location            = module.mod_azure_region_lookup.location_cli
  resource_group_name = azurerm_resource_group.sql-rg.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "test"
  }
}

resource "azurerm_subnet" "sql-snet" {
  depends_on = [
    azurerm_resource_group.sql-rg,
    azurerm_virtual_network.sql-vnet
  ]
  name                 = "sql-service-subnet"
  resource_group_name  = azurerm_resource_group.sql-rg.name
  virtual_network_name = azurerm_virtual_network.sql-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "sql-nsg" {
  depends_on = [
    azurerm_resource_group.sql-rg,
  ]
  name                = "sql-service-nsg"
  location            = module.mod_azure_region_lookup.location_cli
  resource_group_name = azurerm_resource_group.sql-rg.name
  tags = {
    environment = "test"
  }
}

resource "azurerm_log_analytics_workspace" "sql-log" {
  depends_on = [
    azurerm_resource_group.sql-rg
  ]
  name                = "sql-service-log"
  location            = module.mod_azure_region_lookup.location_cli
  resource_group_name = azurerm_resource_group.sql-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    environment = "test"
  }
}

