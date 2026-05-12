#---------------------------------------------------------
# Azure SQL Firewall Rule - Default is "false"
#---------------------------------------------------------

resource "azurerm_mssql_firewall_rule" "fw01" {
  count            = var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
  name             = element(var.firewall_rules, count.index).name
  server_id        = azurerm_mssql_server.primary_sql.id
  start_ip_address = element(var.firewall_rules, count.index).start_ip_address
  end_ip_address   = element(var.firewall_rules, count.index).end_ip_address
}

resource "azurerm_mssql_firewall_rule" "fw02" {
  count            = var.enable_failover_group && var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
  name             = element(var.firewall_rules, count.index).name
  server_id        = azurerm_mssql_server.secondary_sql[0].id
  start_ip_address = element(var.firewall_rules, count.index).start_ip_address
  end_ip_address   = element(var.firewall_rules, count.index).end_ip_address
}
