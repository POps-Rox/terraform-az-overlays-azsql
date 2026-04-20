# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    mssql = {
      source  = "betr-io/mssql"
      version = ">= 0.2.5"
    }
    popsrox-utils = {
      source  = "POps-Rox/azutils"
      version = "~> 1.0.4"
    }
  }
}
