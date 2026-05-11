# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Single Database
module "mod_sql_single" {
  depends_on = [
    azurerm_virtual_network.sql-vnet
  ]
  source = "../.."
  #source  = "github.com/POps-Rox/terraform-az-overlays-azsql"
  #version = "x.x.x"

  # By default, this module will create a resource group and 
  # provide a name for an existing resource group. If you wish 
  # to use an existing resource group, change the option 
  # to "create_sql_resource_group = false." The location of the group 
  # will remain the same if you use the current resource.
  existing_resource_group_name = azurerm_resource_group.sql-rg.name
  location                     = module.mod_azure_region_lookup.location_cli
  environment                  = "public"
  deploy_environment           = "dev"
  org_name                     = "anoa"
  workload_name                = "dev-sql"

  # The admin of the SQL Server. If you do not provide a password,
  # the module will generate a password for you.
  # The password must be at least 8 characters long and contain
  # characters from three of the following categories: English uppercase letters,
  # English lowercase letters, numbers (0-9), and non-alphanumeric characters (!, $, #, %, etc.).
  administrator_login    = "adminsqltest"
  administrator_password = "P@ssw0rd1234"

  # To create a database users set `create_databases_users` to `true`
  create_databases_users = false

  # Create a database.
  databases = [
    {
      name        = "db1"
      max_size_gb = 5
    }
  ]

  # Creating Private Endpoint requires, VNet name and address prefix to create a subnet
  # By default this will create a `privatelink.database.windows.net` DNS zone. 
  # To use existing private DNS zone specify `existing_private_dns_zone` with valid zone name
  enable_private_endpoint      = true
  virtual_network_name         = azurerm_virtual_network.sql-vnet.name
  existing_private_subnet_name = azurerm_subnet.sql-snet.name
  existing_private_dns_zone    = azurerm_private_dns_zone.sql-pdns.name

  # (Optional) To enable Azure Monitoring for Azure SQL database including audit logs
  # Log Analytic workspace resource id required to enable Azure SQL database audit logs
  # enable_sql_server_extended_auditing is required for auditing, default value is false
  # log_retention_days is optional, default value is 30 days  
  enable_log_monitoring               = true
  enable_sql_server_extended_auditing = true
  log_analytics_workspace_id          = azurerm_log_analytics_workspace.sql-log.id

  # Tags for Azure Resources
  add_tags = {
    example = "Basic_SQL_Single_Database_with_Existing_Private_Endpoint"
  }
}
