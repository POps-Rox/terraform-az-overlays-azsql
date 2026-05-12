# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Storage Account to keep Audit logs - Default is "false"
#----------------------------------------------------------

resource "random_string" "str" {
  count   = var.enable_sql_server_extended_auditing || var.enable_database_extended_auditing_policy || var.enable_sql_vulnerability_assessment ? 1 : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    name = local.storage_account_name
  }
}

resource "azurerm_storage_account" "storeacc" {
  count                      = var.enable_sql_server_extended_auditing || var.enable_database_extended_auditing_policy || var.enable_sql_vulnerability_assessment || var.enable_log_monitoring == true ? 1 : 0
  name                       = local.storage_account_name == null ? "stsqlauditlogs${element(concat(random_string.str[*].result, [""]), 0)}" : substr(local.storage_account_name, 0, 24)
  resource_group_name        = local.resource_group_name
  location                   = local.location
  account_kind               = "StorageV2"
  account_tier               = "Standard"
  account_replication_type   = "GRS"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  tags                       = merge({ "Name" = format("%s", "stsqlauditlogs") }, var.add_tags, )
}

resource "azurerm_storage_container" "storcont" {
  count                 = var.enable_sql_vulnerability_assessment ? 1 : 0
  name                  = "vulnerability-assessment"
  storage_account_name  = azurerm_storage_account.storeacc[0].name
  container_access_type = "private"
}

#---------------------------------------------------------
# MSSQL Server Extended Auditing Policy
#----------------------------------------------------------

resource "azurerm_mssql_server_extended_auditing_policy" "primary" {
  count                                   = var.enable_sql_server_extended_auditing ? 1 : 0
  server_id                               = azurerm_mssql_server.primary_sql.id
  storage_endpoint                        = azurerm_storage_account.storeacc[0].primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.storeacc[0].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.log_retention_days
  log_monitoring_enabled                  = var.enable_log_monitoring && var.log_analytics_workspace_id != null ? true : false
}

resource "azurerm_mssql_server_extended_auditing_policy" "secondary" {
  count                                   = var.enable_sql_server_extended_auditing && var.enable_failover_group ? 1 : 0
  server_id                               = azurerm_mssql_server.secondary_sql[0].id
  storage_endpoint                        = azurerm_storage_account.storeacc[0].primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.storeacc[0].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.log_retention_days
  log_monitoring_enabled                  = var.enable_log_monitoring && var.log_analytics_workspace_id != null ? true : false
}

#-----------------------------------------------------------------------------------------------
# SQL ServerVulnerability assessment and alert to admin team  - Default is "false"
#-----------------------------------------------------------------------------------------------

resource "azurerm_mssql_server_security_alert_policy" "sap_primary" {
  count                      = var.enable_sql_vulnerability_assessment ? 1 : 0
  resource_group_name        = local.resource_group_name
  server_name                = azurerm_mssql_server.primary_sql.name
  state                      = "Enabled"
  email_account_admins       = true
  email_addresses            = var.email_addresses_for_alerts
  retention_days             = var.sql_server_extended_auditing_retention_days
  disabled_alerts            = []
  storage_account_access_key = azurerm_storage_account.storeacc[0].primary_access_key
  storage_endpoint           = azurerm_storage_account.storeacc[0].primary_blob_endpoint
}

resource "azurerm_mssql_server_security_alert_policy" "sap_secondary" {
  count                      = var.enable_sql_vulnerability_assessment && var.enable_failover_group ? 1 : 0
  resource_group_name        = local.resource_group_name
  server_name                = azurerm_mssql_server.secondary_sql[0].name
  state                      = "Enabled"
  email_account_admins       = true
  email_addresses            = var.email_addresses_for_alerts
  retention_days             = var.sql_server_extended_auditing_retention_days
  disabled_alerts            = []
  storage_account_access_key = azurerm_storage_account.storeacc[0].primary_access_key
  storage_endpoint           = azurerm_storage_account.storeacc[0].primary_blob_endpoint
}

resource "azurerm_mssql_server_vulnerability_assessment" "va_primary" {
  count                           = var.enable_sql_vulnerability_assessment ? 1 : 0
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.sap_primary[0].id
  storage_container_path          = "${azurerm_storage_account.storeacc[0].primary_blob_endpoint}${azurerm_storage_container.storcont[0].name}/"
  storage_account_access_key      = azurerm_storage_account.storeacc[0].primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = var.email_addresses_for_alerts
  }
}

resource "azurerm_mssql_server_vulnerability_assessment" "va_secondary" {
  count                           = var.enable_sql_vulnerability_assessment && var.enable_failover_group == true ? 1 : 0
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.sap_secondary[0].id
  storage_container_path          = "${azurerm_storage_account.storeacc[0].primary_blob_endpoint}${azurerm_storage_container.storcont[0].name}/"
  storage_account_access_key      = azurerm_storage_account.storeacc[0].primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = var.email_addresses_for_alerts
  }
}

#---------------------------------------------------------
# SqlDb Extended Auditing Policy
#----------------------------------------------------------

resource "azurerm_mssql_database_extended_auditing_policy" "elastic_pool_db" {
  for_each = var.enable_database_extended_auditing_policy ? try({ for db in var.databases : db.name => db if var.enable_elastic_pool == true }, {}) : {}

  database_id                             = azurerm_mssql_database.elastic_pool_database[each.key].id
  storage_endpoint                        = var.security_storage_account_blob_endpoint
  storage_account_access_key              = var.security_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.databases_extended_auditing_retention_days
}

resource "azurerm_mssql_database_extended_auditing_policy" "single_db" {
  for_each = var.enable_database_extended_auditing_policy ? try({ for db in var.databases : db.name => db if var.enable_elastic_pool == false }, {}) : {}

  database_id                             = azurerm_mssql_database.single_database[each.key].id
  storage_endpoint                        = var.security_storage_account_blob_endpoint
  storage_account_access_key              = var.security_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.databases_extended_auditing_retention_days
}
