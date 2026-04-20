# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  # Naming locals/constants
  name_prefix = lower(var.name_prefix)
  name_suffix = lower(var.name_suffix)

  resource_group_name   = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, module.mod_sql_rg.*.resource_group_name, [""]), 0)
  location              = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, module.mod_sql_rg.*.resource_group_location, [""]), 0)
  primary_server_name   = coalesce(var.server_custom_name, data.popsrox_resource_name.primary_sql.result)
  secondary_server_name = var.enable_failover_group ? coalesce(var.server_custom_name, data.popsrox_resource_name.secondary_sql.result) : null
  elastic_pool_name     = coalesce(var.elastic_pool_custom_name, data.popsrox_resource_name.sql_pool.result)
  storage_account_name  = coalesce(var.elastic_pool_custom_name, data.popsrox_resource_name.sql_storage.result)
}
