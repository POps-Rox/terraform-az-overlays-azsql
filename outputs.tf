# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  value       = local.resource_group_name
}

output "resource_group_location" {
  description = "The location of the resource group in which resources are created"
  value       = local.location
}

output "sql_administrator_login" {
  description = "SQL Administrator login"
  value       = var.administrator_login == null ? "sqladmin" : var.administrator_login
  sensitive   = true
}

output "sql_administrator_password" {
  description = "SQL Administrator password"
  value       = var.administrator_password == null ? random_password.main.result : var.administrator_password
  sensitive   = true
}

output "primary_sql_server_id" {
  description = "The primary Microsoft SQL Server ID"
  value       = azurerm_mssql_server.primary_sql.id
}

output "primary_sql_server_fqdn" {
  description = "The fully qualified domain name of the primary Azure SQL Server"
  value       = azurerm_mssql_server.primary_sql.fully_qualified_domain_name
}

output "secondary_sql_server_id" {
  description = "The secondary Microsoft SQL Server ID"
  value       = element(concat(azurerm_mssql_server.secondary_sql.*.id, [""]), 0)
}

output "secondary_sql_server_fqdn" {
  description = "The fully qualified domain name of the secondary Azure SQL Server"
  value       = element(concat(azurerm_mssql_server.secondary_sql.*.fully_qualified_domain_name, [""]), 0)
}

output "sql_elastic_pool" {
  description = "SQL Elastic Pool"
  value       = try(azurerm_mssql_elasticpool.elastic_pool[0], null)
}

output "sql_databases" {
  description = "SQL Databases"
  value       = var.enable_elastic_pool ? azurerm_mssql_database.elastic_pool_database : azurerm_mssql_database.single_database
}

output "sql_elastic_pool_id" {
  description = "ID of the SQL Elastic Pool"
  value       = var.enable_elastic_pool ? azurerm_mssql_elasticpool.elastic_pool[0].id : null
}

output "sql_databases_id" {
  description = "Map of the SQL Databases IDs"
  value       = var.enable_elastic_pool ? { for db in azurerm_mssql_database.elastic_pool_database : db.name => db.id } : { for db in azurerm_mssql_database.single_database : db.name => db.id }
}

output "default_administrator_databases_connection_strings" {
  description = "Map of the SQL Databases with administrator credentials connection strings"
  value = var.enable_elastic_pool ? {
    for db in azurerm_mssql_database.elastic_pool_database : db.name => formatlist(
      "Server=tcp:%s;Database=%s;User ID=%s;Password=%s;Encrypt=true;",
      azurerm_mssql_server.primary_sql.fully_qualified_domain_name,
      db.name,
      var.administrator_login,
      var.administrator_password
    )
    } : {
    for db in azurerm_mssql_database.single_database : db.name => formatlist(
      "Server=tcp:%s;Database=%s;User ID=%s;Password=%s;Encrypt=true;",
      azurerm_mssql_server.primary_sql.fully_qualified_domain_name,
      db.name,
      var.administrator_login,
      var.administrator_password
    )
  }
  sensitive = true
}

output "default_databases_users" {
  description = "Map of the SQL Databases dedicated users"
  value = {
    for db_user in local.databases_users :
    db_user.database => { "user_name" = db_user.username, "password" = module.databases_users[format("%s-%s", db_user.username, db_user.database)].database_user_password }
  }
  sensitive = true
}

output "custom_databases_users" {
  description = "Map of the custom SQL Databases users"
  value = {
    for custom_user in var.custom_users :
    custom_user.database => { "user_name" = custom_user.name, "password" = module.custom_users[format("%s-%s", custom_user.name, custom_user.database)].database_user_password }...
  }
  sensitive = true
}

output "custom_databases_users_roles" {
  description = "Map of the custom SQL Databases users roles"
  value = {
    for custom_user in var.custom_users :
    join("-", [custom_user.name, custom_user.database]) => module.custom_users[join("-", [custom_user.name, custom_user.database])].database_user_roles
  }
}

output "identity" {
  description = "Identity block with principal ID and tenant ID used for this SQL Server"
  value       = try(azurerm_mssql_server.primary_sql.identity[0], null)
}

output "sql_failover_group_id" {
  description = "A failover group of databases on a collection of Azure SQL servers."
  value       = element(concat(azurerm_mssql_failover_group.fog.*.id, [""]), 0)
}

output "primary_sql_server_private_endpoint" {
  description = "id of the Primary SQL server Private Endpoint"
  value       = element(concat(azurerm_private_endpoint.pep.*.id, [""]), 0)
}

output "sql_server_private_dns_zone_domain" {
  description = "DNS zone name of SQL server Private endpoints dns name records"
  value       = var.existing_private_dns_zone == null && var.enable_private_endpoint ? element(concat(azurerm_private_dns_zone.dns_zone.*.name, [""]), 0) : var.existing_private_dns_zone
}
