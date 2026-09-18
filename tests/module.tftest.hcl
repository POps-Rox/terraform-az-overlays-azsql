mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      object_id = "00000000-0000-0000-0000-000000000001"
      tenant_id = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_data "azurerm_resource_group" {
    defaults = {
      location = "eastus2"
    }
  }

  mock_data "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sql/providers/Microsoft.Network/virtualNetworks/vnet-sql"
    }
  }

  mock_data "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sql/providers/Microsoft.Network/virtualNetworks/vnet-sql/subnets/snet-sql"
    }
  }

  mock_data "azurerm_private_endpoint_connection" {
    defaults = {
      private_service_connection = [
        {
          private_ip_address = "10.10.1.4"
        }
      ]
    }
  }

  mock_data "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sql/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"
    }
  }
}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "generated-sql-name"
    }
  }
}

variables {
  location                     = "eastus2"
  environment                  = "public"
  existing_resource_group_name = "rg-sql"
  administrator_login          = "sqladminuser"
  administrator_password       = "P@ssword123456789"
  create_databases_users       = false
}

run "custom_name_override_precedence" {
  command = plan

  variables {
    server_custom_name       = "custom-primary-sql"
    elastic_pool_custom_name = "custom-elastic-pool"
    enable_elastic_pool      = true
    elastic_pool_sku = {
      tier     = "GeneralPurpose"
      capacity = 2
    }
  }

  assert {
    condition     = azurerm_mssql_server.primary_sql.name == "custom-primary-sql"
    error_message = "server_custom_name must override the generated SQL server name."
  }

  assert {
    condition     = azurerm_mssql_elasticpool.elastic_pool[0].name == "custom-elastic-pool"
    error_message = "elastic_pool_custom_name must override the generated elastic pool name."
  }
}

run "empty_custom_names_fall_through_to_generated_names" {
  command = plan

  variables {
    server_custom_name       = ""
    elastic_pool_custom_name = ""
    enable_elastic_pool      = true
    elastic_pool_sku = {
      tier     = "GeneralPurpose"
      capacity = 2
    }
  }

  assert {
    condition     = azurerm_mssql_server.primary_sql.name == "generated-sql-name"
    error_message = "An empty server_custom_name must fall through to the generated name."
  }

  assert {
    condition     = azurerm_mssql_elasticpool.elastic_pool[0].name == "generated-sql-name"
    error_message = "An empty elastic_pool_custom_name must fall through to the generated name."
  }
}

run "disabled_feature_conditionals_omit_optional_resources" {
  command = plan

  variables {
    enable_elastic_pool          = false
    enable_failover_group        = false
    enable_firewall_rules        = false
    enable_private_endpoint      = false
    enable_log_monitoring        = false
    virtual_network_name         = "vnet-sql"
    existing_private_subnet_name = "snet-sql"
    firewall_rules = [
      {
        name             = "office"
        start_ip_address = "192.0.2.1"
        end_ip_address   = "192.0.2.1"
      }
    ]
    allowed_subnets_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sql/providers/Microsoft.Network/virtualNetworks/vnet-sql/subnets/snet-sql"
    ]
    databases = []
  }

  assert {
    condition     = length(azurerm_mssql_server.secondary_sql) == 0
    error_message = "Disabling failover must omit the secondary SQL server."
  }

  assert {
    condition     = length(azurerm_mssql_failover_group.fog) == 0
    error_message = "Disabling failover must omit the failover group."
  }

  assert {
    condition     = length(azurerm_private_endpoint.pep) == 0
    error_message = "Disabling private endpoints must omit the primary private endpoint."
  }

  assert {
    condition     = length(azurerm_mssql_firewall_rule.fw01) == 0
    error_message = "Disabling firewall rules must omit primary firewall rules even when rules are supplied."
  }

  assert {
    condition     = length(azurerm_storage_account.storeacc) == 0
    error_message = "Disabling auditing, vulnerability assessment, and log monitoring must omit the audit storage account."
  }
}

run "enabled_feature_conditionals_create_optional_resources" {
  command = plan

  variables {
    enable_failover_group        = true
    enable_firewall_rules        = true
    enable_private_endpoint      = true
    enable_log_monitoring        = true
    elastic_pool_custom_name     = "sqlteststore"
    virtual_network_name         = "vnet-sql"
    existing_private_subnet_name = "snet-sql"
    log_analytics_workspace_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sql/providers/Microsoft.OperationalInsights/workspaces/law-sql"
    firewall_rules = [
      {
        name             = "office"
        start_ip_address = "192.0.2.1"
        end_ip_address   = "192.0.2.1"
      }
    ]
    allowed_subnets_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sql/providers/Microsoft.Network/virtualNetworks/vnet-sql/subnets/snet-sql"
    ]
    databases = [
      {
        name        = "appdb"
        max_size_gb = 32
      }
    ]
  }

  assert {
    condition     = length(azurerm_mssql_server.secondary_sql) == 1
    error_message = "Enabling failover must create one secondary SQL server."
  }

  assert {
    condition     = length(azurerm_mssql_failover_group.fog) == 1
    error_message = "Enabling failover must create one failover group."
  }

  assert {
    condition     = length(azurerm_private_endpoint.pep) == 1 && length(azurerm_private_endpoint.pep2) == 1
    error_message = "Enabling private endpoints with failover must create primary and secondary private endpoints."
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.vnet_link) == 1
    error_message = "Creating a private DNS zone must link it to the virtual network."
  }

  assert {
    condition     = length(azurerm_mssql_firewall_rule.fw01) == 1 && length(azurerm_mssql_firewall_rule.fw02) == 1
    error_message = "Enabling firewall rules with failover must create rules for both servers."
  }

  assert {
    condition     = length(azurerm_storage_account.storeacc) == 1
    error_message = "Enabling log monitoring must create the audit storage account."
  }
}

run "tags_and_location_are_preserved" {
  command = plan

  variables {
    location           = "westus2"
    deploy_environment = "test"
    workload_name      = "azsql"
    add_tags = {
      workload = "override-workload"
      cost     = "1234"
    }
    server_add_tags = {
      cost  = "server-cost"
      owner = "database-team"
    }
    databases = [
      {
        name        = "appdb"
        max_size_gb = 32
        database_add_tags = {
          owner = "app-team"
        }
      }
    ]
  }

  assert {
    condition     = azurerm_mssql_server.primary_sql.location == "eastus2"
    error_message = "The SQL server location must pass through from the selected resource group."
  }

  assert {
    condition     = output.resource_group_location == "eastus2"
    error_message = "The resource_group_location output must expose the selected resource group location."
  }

  assert {
    condition     = azurerm_mssql_server.primary_sql.tags["environment"] == "test"
    error_message = "Default tags must include the deploy environment."
  }

  assert {
    condition     = azurerm_mssql_server.primary_sql.tags["workload"] == "override-workload"
    error_message = "add_tags must override default tags when keys overlap."
  }

  assert {
    condition     = azurerm_mssql_server.primary_sql.tags["cost"] == "server-cost"
    error_message = "server_add_tags must override shared add_tags on the SQL server."
  }

  assert {
    condition     = azurerm_mssql_database.single_database["appdb"].tags["owner"] == "app-team"
    error_message = "database_add_tags must be merged into database tags."
  }
}
