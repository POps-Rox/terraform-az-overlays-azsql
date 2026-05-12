# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#---------------------------------------------------------
# Azure Region Lookup
#----------------------------------------------------------
module "mod_azure_region_lookup" {
  source = "github.com/POps-Rox/terraform-az-overlays-azregionslookup?ref=v2.0.0"

  azure_region = "eastus"
}

