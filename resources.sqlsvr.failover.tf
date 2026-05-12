
#---------------------------------------------------------
# Azure SQL Failover Group - Default is "false" 
#---------------------------------------------------------

resource "azurerm_mssql_failover_group" "fog" {
  count     = var.enable_failover_group ? 1 : 0
  name      = "sqldb-failover-group"
  server_id = azurerm_mssql_server.primary_sql.id
  databases = [for db in azurerm_mssql_database.single_database : db.id]
  tags      = merge({ "Name" = format("%s", "sqldb-failover-group") }, local.default_tags, var.add_tags, )

  partner_server {
    id = azurerm_mssql_server.secondary_sql[0].id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }

  readonly_endpoint_failover_policy_enabled = true
}