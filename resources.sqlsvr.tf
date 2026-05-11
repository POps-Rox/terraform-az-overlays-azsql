# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "random_password" "main" {
  length      = var.random_password_length
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    administrator_login_password = local.primary_server_name
  }
}

resource "azurerm_mssql_server" "primary_sql" {
  name                = local.primary_server_name
  resource_group_name = local.resource_group_name
  location            = local.location

  version                              = var.server_version
  connection_policy                    = var.connection_policy
  minimum_tls_version                  = var.tls_minimum_version
  public_network_access_enabled        = var.public_network_access_enabled
  outbound_network_restriction_enabled = var.outbound_network_restriction_enabled

  administrator_login          = var.administrator_login == null ? "sqladmin" : var.administrator_login
  administrator_login_password = var.administrator_password == null ? random_password.main.result : var.administrator_password

  dynamic "identity" {
    for_each = var.enable_identity == true ? [1] : [0]
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "azuread_administrator" {
    for_each = var.ad_admin_login_name != null ? [1] : []
    content {
      login_username = var.ad_admin_login_name
      object_id      = data.azurerm_client_config.current.object_id
      tenant_id      = data.azurerm_client_config.current.tenant_id
    }
  }

  tags = merge(local.default_tags, var.add_tags, var.server_add_tags)
}

#-------------------------------------------------------------
# SQL servers - Secondary server is depends_on Failover Group
#-------------------------------------------------------------

resource "azurerm_mssql_server" "secondary_sql" {
  count               = var.enable_failover_group ? 1 : 0
  name                = local.secondary_server_name
  resource_group_name = local.resource_group_name
  location            = local.location

  version                              = var.server_version
  connection_policy                    = var.connection_policy
  minimum_tls_version                  = var.tls_minimum_version
  public_network_access_enabled        = var.public_network_access_enabled
  outbound_network_restriction_enabled = var.outbound_network_restriction_enabled

  administrator_login          = var.administrator_login == null ? "sqladmin" : var.administrator_login
  administrator_login_password = var.administrator_password == null ? random_password.main.result : var.administrator_password

  dynamic "identity" {
    for_each = var.enable_identity == true ? [1] : [0]
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "azuread_administrator" {
    for_each = var.ad_admin_login_name != null ? [1] : []
    content {
      login_username = var.ad_admin_login_name
      object_id      = data.azurerm_client_config.current.object_id
      tenant_id      = data.azurerm_client_config.current.tenant_id
    }
  }

  tags = merge(local.default_tags, var.add_tags, var.server_add_tags)
}

#-------------------------------------------------------------
# SQL servers - elasticpool
#-------------------------------------------------------------

resource "azurerm_mssql_elasticpool" "elastic_pool" {
  count = var.enable_elastic_pool ? 1 : 0

  name = local.elastic_pool_name

  location            = local.location
  resource_group_name = local.resource_group_name

  license_type = var.elastic_pool_license_type

  server_name = azurerm_mssql_server.primary_sql.name

  per_database_settings {
    max_capacity = coalesce(var.elastic_pool_databases_max_capacity, var.elastic_pool_sku.capacity)
    min_capacity = var.elastic_pool_databases_min_capacity
  }

  max_size_gb    = var.elastic_pool_max_size
  zone_redundant = var.elastic_pool_zone_redundant

  sku {
    capacity = local.elastic_pool_sku.capacity
    name     = local.elastic_pool_sku.name
    tier     = local.elastic_pool_sku.tier
    family   = local.elastic_pool_sku.family
  }

  tags = merge(local.default_tags, var.add_tags, var.elastic_pool_add_tags)
}
