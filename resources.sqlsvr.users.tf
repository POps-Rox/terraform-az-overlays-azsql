# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

module "databases_users" {
  for_each = try({ for user in local.databases_users : format("%s-%s", user.username, user.database) => user }, {})

  source = "./modules/sql_db_users"

  depends_on = [
    azurerm_mssql_database.single_database,
    azurerm_mssql_database.elastic_pool_database
  ]

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  sql_server_hostname = azurerm_mssql_server.primary_sql.fully_qualified_domain_name

  database_name = each.value.database
  user_name     = each.key
  user_roles    = each.value.roles
}

module "custom_users" {
  for_each = try({ for custom_user in var.custom_users : format("%s-%s", custom_user.name, custom_user.database) => custom_user }, {})

  source = "./modules/sql_db_users"

  depends_on = [
    azurerm_mssql_database.single_database,
    azurerm_mssql_database.elastic_pool_database
  ]

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  sql_server_hostname = azurerm_mssql_server.primary_sql.fully_qualified_domain_name

  database_name = var.enable_elastic_pool ? azurerm_mssql_database.elastic_pool_database[each.value.database].name : azurerm_mssql_database.single_database[each.value.database].name
  user_name     = each.value.name
  user_roles    = each.value.roles
}

#-----------------------------------------------------------------------------------------------
# Adding AD Admin to SQL Server - now inlined as `azuread_administrator` block on
# `azurerm_mssql_server.{primary,secondary}_sql` (azurerm 4.x removed the standalone
# `azurerm_sql_active_directory_administrator` resource).
#-----------------------------------------------------------------------------------------------
