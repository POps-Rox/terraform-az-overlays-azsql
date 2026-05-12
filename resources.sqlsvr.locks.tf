# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#------------------------------------------------------------------
# Azure SQl Database Lock configuration - Default (required). 
#------------------------------------------------------------------
resource "azurerm_management_lock" "primary_sql_level_lock" {
  count      = var.enable_resource_locks ? 1 : 0
  name       = "${local.primary_server_name}-${var.lock_level}-lock"
  scope      = azurerm_mssql_server.primary_sql.id
  lock_level = var.lock_level
  notes      = "Azure SQl Server Primary '${local.primary_server_name}' is locked with '${var.lock_level}' level."
}

resource "azurerm_management_lock" "secondary_sql_level_lock" {
  count      = var.enable_resource_locks && var.enable_failover_group ? 1 : 0
  name       = "${local.secondary_server_name}-${var.lock_level}-lock"
  scope      = azurerm_mssql_server.secondary_sql[0].id
  lock_level = var.lock_level
  notes      = "Azure SQl Server Secondary '${local.secondary_server_name}' is locked with '${var.lock_level}' level."
}
