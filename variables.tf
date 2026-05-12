# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###########################
# Global Configuration   ##
###########################

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
  default     = null
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
}

variable "org_name" {
  description = "A name for the organization. It defaults to anoa."
  type        = string
  default     = "anoa"
}

variable "workload_name" {
  description = "A name for the workload. It defaults to acr."
  type        = string
  default     = "acr"
}

variable "deploy_environment" {
  description = "The environment to deploy. It defaults to dev."
  type        = string
  default     = "dev"
}

variable "random_password_length" {
  type        = number
  description = "The desired length of random password created by this module"
  default     = 32
}

#######################
# RG Configuration   ##
#######################

variable "create_sql_resource_group" {
  description = "Controls if the resource group should be created. If set to false, the resource group name must be provided. Default is false."
  type        = bool
  default     = false
}

variable "use_location_short_name" {
  description = "Use short location name for resources naming (ie eastus -> eus). Default is true. If set to false, the full cli location name will be used. if custom naming is set, this variable will be ignored."
  type        = bool
  default     = true
}

variable "existing_resource_group_name" {
  description = "The name of the existing resource group to use. If not set, the name will be generated using the `org_name`, `workload_name`, `deploy_environment` and `environment` variables."
  type        = string
  default     = null
}

#####################################
# Private Endpoint Configuration   ##
#####################################

variable "enable_private_endpoint" {
  type        = bool
  description = "Manages a Private Endpoint to Azure SQL. Default is false."
  default     = false
}

variable "existing_private_dns_zone" {
  type        = any
  description = "Name of the existing private DNS zone"
  default     = null
}

variable "existing_private_subnet_name" {
  type        = any
  description = "Name of the existing private subnet for the private endpoint"
  default     = null
}

variable "virtual_network_name" {
  type        = any
  description = "Name of the virtual network for the private endpoint"
  default     = null
}

########################
# Sql Configuration   ##
########################

variable "server_version" {
  description = "Version of the SQL Server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server). See https://www.terraform.io/docs/providers/azurerm/r/sql_server.html#version"
  type        = string
  default     = "12.0"
}

variable "enable_failover_group" {
  type        = bool
  description = "Create a failover group of databases on a collection of Azure SQL servers"
  default     = false
}

variable "enable_identity" {
  type        = bool
  description = "If you want your SQL Server to have an managed identity. Defaults to false."
  default     = false
}

variable "administrator_login" {
  description = "Administrator login for SQL Server"
  type        = string
}

variable "administrator_password" {
  description = "Administrator password for SQL Server"
  type        = string
  default     = null
}

variable "single_databases_sku_name" {
  description = "Specifies the name of the SKU used by the database. For example, `GP_S_Gen5_2`, `HS_Gen4_1`, `BC_Gen5_2`. Use only if `enable_elastic_pool` variable is set to `false`. More documentation [here](https://docs.microsoft.com/en-us/azure/azure-sql/database/service-tiers-general-purpose-business-critical)"
  type        = string
  default     = "BC_Gen5_2"
}

variable "create_databases_users" {
  description = "True to create a user named <db>_user on each database with generated password and role db_owner."
  type        = bool
  default     = true
}

variable "databases" {
  description = "List of the databases configurations for this server."
  type = list(object({
    name                        = string
    license_type                = optional(string)
    max_size_gb                 = number
    create_mode                 = optional(string)
    min_capacity                = optional(number)
    auto_pause_delay_in_minutes = optional(number)
    read_scale                  = optional(string)
    read_replica_count          = optional(number)
    creation_source_database_id = optional(string)
    restore_point_in_time       = optional(string)
    recover_database_id         = optional(string)
    restore_dropped_database_id = optional(string)
    storage_account_type        = optional(string, "Geo")
    database_add_tags           = optional(map(string), {})
  }))
  default = []
}

variable "databases_collation" {
  description = "SQL Collation for the databases"
  type        = string
  default     = "SQL_LATIN1_GENERAL_CP1_CI_AS"
}

variable "databases_zone_redundant" {
  description = "True to have databases zone redundant, which means the replicas of the databases will be spread across multiple availability zones. This property is only settable for `Premium` and `Business Critical` databases."
  type        = bool
  default     = null
}

variable "point_in_time_restore_retention_days" {
  description = "Point In Time Restore configuration. Value has to be between `7` and `35`"
  type        = number
  default     = 7
  validation {
    condition     = var.point_in_time_restore_retention_days >= 7 && var.point_in_time_restore_retention_days <= 35
    error_message = "The PITR retention should be between 7 and 35 days."
  }
}

variable "custom_users" {
  description = <<DESC
    List of objects for custom users creation. 
    Password are generated.
    These users are created within the "custom_users" submodule.
DESC
  type = list(object({
    name     = string
    database = string
    roles    = optional(list(string))
  }))
  default = []
}

variable "tls_minimum_version" {
  description = "The TLS minimum version for all SQL Database associated with the server. Valid values are: `1.0`, `1.1` and `1.2`."
  type        = string
  default     = "1.2"
}

variable "backup_retention" {
  description = "Definition of long term backup retention for all the databases in this SQL Server."
  type = object({
    weekly_retention  = optional(number)
    monthly_retention = optional(number)
    yearly_retention  = optional(number)
    week_of_year      = optional(number)
  })
  default = {}
}

variable "ad_admin_login_name" {
  type        = any
  description = "The login name of the principal to set as the server administrator"
  default     = null
}

#####################################
# Sql Elastic Pool Configuration   ##
#####################################

variable "enable_elastic_pool" {
  description = "True to deploy the databases in an ElasticPool, single databases are deployed otherwise."
  type        = bool
  default     = false
}

variable "elastic_pool_sku" {
  description = <<DESC
    SKU for the Elastic Pool with tier and eDTUs capacity. Premium tier with zone redundancy is mandatory for high availability.
    Possible values for tier are `GeneralPurpose`, `BusinessCritical` for vCore models and `Basic`, `Standard`, or `Premium` for DTU based models.
    See https://docs.microsoft.com/en-us/azure/sql-database/sql-database-dtu-resource-limits-elastic-pools"
DESC

  type = object({
    tier     = string,
    capacity = number,
  })
  default = null
}

variable "elastic_pool_license_type" {
  description = "Specifies the license type applied to this database. Possible values are `LicenseIncluded` and `BasePrice`"
  type        = string
  default     = null
}

variable "elastic_pool_max_size" {
  description = "Maximum size of the Elastic Pool in gigabytes"
  type        = string
  default     = null
}

variable "elastic_pool_zone_redundant" {
  description = "True to have the Elastic Pool zone redundant, SKU tier must be Premium to use it. This is mandatory for high availability."
  type        = bool
  default     = false
}

variable "elastic_pool_databases_min_capacity" {
  description = "The minimum capacity (DTU or vCore) all databases are guaranteed in the Elastic Pool. Defaults to 0."
  type        = number
  default     = 0
}

variable "elastic_pool_databases_max_capacity" {
  description = "The maximum capacity (DTU or vCore) any one database can consume in the Elastic Pool. Default to the max Elastic Pool capacity."
  type        = number
  default     = null
}

################################
# Sql Network Configuration   ##
################################

variable "enable_firewall_rules" {
  type        = bool
  description = "Manage an Azure SQL Firewall Rule"
  default     = false
}

variable "firewall_rules" {
  description = "Range of IP addresses to allow firewall connections."
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "allowed_subnets_ids" {
  description = "List of Subnet ID to allow to connect to the SQL Instance"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_list" {
  description = "Allowed IP addresses to access the server in CIDR format. Default to all Azure services"
  type        = list(string)
  default     = ["0.0.0.0/32"]
}

variable "public_network_access_enabled" {
  description = "True to allow public network access for this server"
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Whether outbound network traffic is restricted for this server"
  type        = bool
  default     = false
}

variable "connection_policy" {
  description = "The connection policy the server will use. Possible values are `Default`, `Proxy`, and `Redirect`"
  type        = string
  default     = "Default"
}

##############################
# Sql Audit Configuration   ##
##############################

variable "enable_log_monitoring" {
  type        = bool
  description = "Enable audit events to Azure Monitor?"
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = any
  description = "Specifies the ID of a Log Analytics Workspace where Diagnostics Data to be sent"
  default     = null
}

variable "log_retention_days" {
  description = "Specifies the number of days to keep in the audit logs. Default to 90 days."
  type        = number
  default     = 30
}

variable "disabled_alerts" {
  description = "Specifies an array of alerts that are disabled. Allowed values are: Sql_Injection, Sql_Injection_Vulnerability, Access_Anomaly, Data_Exfiltration, Unsafe_Action."
  type        = list(any)
  default     = []
}

variable "alerting_email_addresses" {
  description = "List of email addresses to send reports for threat detection and vulnerability assesment"
  type        = list(string)
  default     = []
}

variable "enable_threat_detection_policy" {
  description = "True to enable thread detection policy on the databases"
  type        = bool
  default     = false
}

variable "threat_detection_policy_retention_days" {
  description = "Specifies the number of days to keep in the Threat Detection audit logs"
  type        = number
  default     = 7
}

variable "threat_detection_policy_disabled_alerts" {
  description = "Specifies a list of alerts which should be disabled. Possible values include `Access_Anomaly`, `Sql_Injection` and `Sql_Injection_Vulnerability`"
  type        = list(string)
  default     = []
}

variable "databases_extended_auditing_enabled" {
  description = "True to enable extended auditing for SQL databases"
  type        = bool
  default     = false
}

variable "enable_sql_server_extended_auditing" {
  description = "True to enable extended auditing for SQL Server"
  type        = bool
  default     = false
}

variable "sql_server_extended_auditing_retention_days" {
  description = "Server extended auditing logs retention"
  type        = number
  default     = 30
}

variable "enable_sql_vulnerability_assessment" {
  description = "True to enable vulnerability assessment for this SQL Server"
  type        = bool
  default     = false
}

variable "sql_server_security_alerting_enabled" {
  description = "True to enable security alerting for this SQL Server"
  type        = bool
  default     = false
}

variable "email_addresses_for_alerts" {
  description = "List of email addresses to send reports for threat detection and vulnerability assesment"
  type        = list(string)
  default     = []
}

variable "enable_database_extended_auditing_policy" {
  type        = bool
  description = "Manages Extended Audit policy for SQL database"
  default     = false
}

variable "databases_extended_auditing_retention_days" {
  description = "Databases extended auditing logs retention"
  type        = number
  default     = 30
}

variable "security_storage_account_blob_endpoint" {
  description = "Storage Account blob endpoint used to store security logs and reports"
  type        = string
  default     = null
}

variable "security_storage_account_access_key" {
  description = "Storage Account access key used to store security logs and reports"
  type        = string
  default     = null
}

variable "security_storage_account_container_name" {
  description = "Storage Account container name where to store SQL Server vulneralibility assessment"
  type        = string
  default     = null
}
