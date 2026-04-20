# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "popsrox_resource_name" "primary_sql" {
  name          = var.workload_name
  resource_type = "azurerm_mssql_server"
  prefixes      = [var.org_name, module.mod_azure_region_lookup.location_short]
  suffixes      = compact([var.name_prefix == "" ? null : local.name_prefix, var.deploy_environment, local.name_suffix, "primary", var.use_naming ? "" : "sqlsvr"])
  use_slug      = var.use_naming
  clean_input   = true
  separator     = "-"
}

data "popsrox_resource_name" "secondary_sql" {
  name          = var.workload_name
  resource_type = "azurerm_mssql_server"
  prefixes      = [var.org_name, module.mod_azure_region_lookup.location_short]
  suffixes      = compact([var.name_prefix == "" ? null : local.name_prefix, var.deploy_environment, local.name_suffix, "secondary", var.use_naming ? "" : "sqlsvr"])
  use_slug      = var.use_naming
  clean_input   = true
  separator     = "-"
}

data "popsrox_resource_name" "sql_pool" {
  name          = var.workload_name
  resource_type = "azurerm_mssql_elasticpool"
  prefixes      = [var.org_name, module.mod_azure_region_lookup.location_short]
  suffixes      = compact([var.name_prefix == "" ? null : local.name_prefix, var.deploy_environment, local.name_suffix, var.use_naming ? "" : "sqlpool"])
  use_slug      = var.use_naming
  clean_input   = true
  separator     = "-"
}

data "popsrox_resource_name" "sql_dbs" {
  for_each = try({ for database in var.databases : database.name => database }, {})

  name          = var.workload_name
  resource_type = "azurerm_mssql_database"
  prefixes      = [var.org_name, module.mod_azure_region_lookup.location_short]
  suffixes      = compact([var.name_prefix == "" ? null : local.name_prefix, var.deploy_environment, local.name_suffix, var.use_naming ? "" : "sqldb"])
  use_slug      = var.use_naming
  clean_input   = true
  separator     = "-"
}

data "popsrox_resource_name" "sql_storage" {
  name          = var.workload_name
  resource_type = "azurerm_storage_account"
  prefixes      = [var.org_name, module.mod_azure_region_lookup.location_short]
  suffixes      = compact([var.name_prefix == "" ? null : local.name_prefix, var.deploy_environment, local.name_suffix, var.use_naming ? "" : "st"])
  use_slug      = var.use_naming
  clean_input   = true
  separator     = "-"
}
