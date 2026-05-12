# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Private Link for Sql - Default is "false" 
#---------------------------------------------------------
data "azurerm_virtual_network" "vnet" {
  count               = var.enable_private_endpoint && var.virtual_network_name != null ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "snet" {
  count                = var.enable_private_endpoint && var.existing_private_subnet_name != null ? 1 : 0
  name                 = var.existing_private_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet[0].name
  resource_group_name  = local.resource_group_name
}

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint && var.existing_private_subnet_name != null ? 1 : 0
  name                = format("%s-private-endpoint", local.primary_server_name)
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = data.azurerm_subnet.snet[0].id
  tags                = merge({ "Name" = format("%s", "sqldb-private-endpoint") }, var.add_tags, )

  private_service_connection {
    name                           = "sqldbprivatelink-primary"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.primary_sql.id
    subresource_names              = ["sqlServer"]
  }
}

resource "azurerm_private_endpoint" "pep2" {
  count               = var.enable_failover_group && var.enable_private_endpoint ? 1 : 0
  name                = format("%s-secondary", "sqldb-private-endpoint")
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = data.azurerm_subnet.snet[0].id
  tags                = merge({ "Name" = format("%s", "sqldb-private-endpoint") }, var.add_tags, )

  private_service_connection {
    name                           = "sqldbprivatelink-secondary"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.secondary_sql[0].id
    subresource_names              = ["sqlServer"]
  }
}

#------------------------------------------------------------------
# DNS zone & records for SQL Private endpoints - Default is "false" 
#------------------------------------------------------------------
data "azurerm_private_endpoint_connection" "private-ip1" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.pep[0].name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_mssql_server.primary_sql]
}

data "azurerm_private_endpoint_connection" "private-ip2" {
  count               = var.enable_failover_group && var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.pep2[0].name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_mssql_server.secondary_sql]
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = var.environment == "public" ? "privatelink.database.windows.net" : "privatelink.database.usgovcloudapi.net"
  resource_group_name = local.resource_group_name
  tags                = merge({ "Name" = format("%s", "Azure-Sql-Private-DNS-Zone") }, local.default_tags, var.add_tags, )
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count                 = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                  = "vnet-private-zone-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dns_zone[0].name : var.existing_private_dns_zone
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id
  registration_enabled  = false
  tags                  = merge({ "Name" = format("%s", "vnet-private-zone-link") }, local.default_tags, var.add_tags, )
}

resource "azurerm_private_dns_a_record" "a_rec1" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_mssql_server.primary_sql.name
  zone_name           = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dns_zone[0].name : var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.private-ip1[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "a_rec2" {
  count               = var.enable_failover_group && var.enable_private_endpoint ? 1 : 0
  name                = azurerm_mssql_server.secondary_sql[0].name
  zone_name           = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dns_zone[0].name : var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.private-ip2[0].private_service_connection[0].private_ip_address]

}