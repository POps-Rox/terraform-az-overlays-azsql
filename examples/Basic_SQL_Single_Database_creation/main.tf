
module "mod_mssql_single" {
  source = "../.."
  # source  = "github.com/POps-Rox/terraform-az-overlays-azsql?ref=v2.0.0"
  # version = "x.x.x"

  # By default, this module will create a resource group and 
  # provide a name for an existing resource group. If you wish 
  # to use an existing resource group, change the option 
  # to "create_sql_resource_group = false." The location of the group 
  # will remain the same if you use the current resource.
  create_sql_resource_group = true
  location                  = module.mod_azure_region_lookup.location_cli
  environment               = "public"
  deploy_environment        = "dev"
  org_name                  = "anoa"
  workload_name             = "dev-sql"

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

  # Tags for Azure Resources
  add_tags = {
    example = "Basic_SQL_Single_Database_creation"
  }
}
