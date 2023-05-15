# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
SUMMARY: Module to deploy an SCCA Compliant Platform Hub/Spoke Landing Zone. Management Hub network using the 
[Microsoft recommended Hub-Spoke network topology](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke). 
Usually, only one hub in each region with multiple spokes and each of the spokes can also be in separate subscriptions. 
This reference implementation will deploy a hub network with a two spokes network and all on one subscription.
DESCRIPTION: The following components will be options in this deployment
              * Hub Virtual Network (VNet)              
              * Bastion Host (Optional)
              * Microsoft Defender for Cloud (Optional)              
            * Spokes              
              * Operations (Tier 1)
              * Shared Services (Tier 2)
            * Logging
              * Azure Sentinel
              * Azure Log Analytics
              * Azure Monitor
              * AMPLS (Azure Monitor Private Link Scope)
            * Azure Firewall
            * Private DNS Zones - Details of all the Azure Private DNS zones can be found here --> [https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration)
AUTHOR/S: jspinella
*/

################################
### Hub/Spoke Configuations  ###
################################

#######################################
### Hub Network Configuration       ###
#######################################

module "mod_hub_network" {
  providers = { azurerm = azurerm.hub }
  source    = "azurenoops/overlays-management-hub/azurerm"
  version   = ">= 2.0.0"

  # By default, this module will create a resource group, provide the name here
  # To use an existing resource group, specify the existing resource group name, 
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG.
  create_resource_group = true
  location              = var.location
  deploy_environment    = var.deploy_environment
  org_name              = var.org_name
  environment           = var.environment
  workload_name         = var.hub_name

  # Provide valid VNet Address space and specify valid domain name for Private DNS Zone.  
  virtual_network_address_space           = var.hub_vnet_address_space              # (Required)  Hub Virtual Network Parameters  
  firewall_subnet_address_prefix          = var.fw_client_snet_address_prefixes     # (Required)  Hub Firewall Subnet Parameters  
  ampls_subnet_address_prefix             = var.ampls_subnet_address_prefix         # (Required)  AMPLS Subnet Parameters
  firewall_management_snet_address_prefix = var.fw_management_snet_address_prefixes # (Optional)  Hub Firewall Management Subnet Parameters
  gateway_subnet_address_prefix           = var.gateway_vnet_address_space          # (Optional)  Hub Gateway Subnet Parameters

  # (Required) Hub Subnets 
  # Default Subnets, Service Endpoints
  # This is the default subnet with required configuration, check README.md for more details
  # subnet name will be set as per Azure NoOps naming convention by defaut. expected value here is: <App or project name>
  hub_subnets = var.hub_subnets

  # Enable Flow Logs
  # By default, this will enable flow logs for all subnets.
  enable_traffic_analytics = var.enable_traffic_analytics

  # By default, this will module will deploy management logging.
  # If you do not want to enable management logging, 
  # set enable_management_logging to false.
  # All Log solutions are enabled (true) by default. To disable a solution, set the argument to `enable_<solution_name> = false`.
  enable_management_logging = true

  # Firewall Settings
  # By default, Azure NoOps will create Azure Firewall in Hub VNet. 
  # If you do not want to create Azure Firewall, 
  # set enable_firewall to false. This will allow different firewall products to be used (Example: F5).  
  enable_firewall = var.enable_firewall

  # By default, forced tunneling is enabled for Azure Firewall.
  # If you do not want to enable forced tunneling, 
  # set enable_forced_tunneling to false.
  enable_forced_tunneling = var.enable_forced_tunneling

  # (Optional) To enable the availability zones for firewall. 
  # Availability Zones can only be configured during deployment 
  # You can't modify an existing firewall to include Availability Zones
  firewall_zones = var.firewall_zones

  # # (Optional) specify the Network rules for Azure Firewall l
  # This is default values, do not need this if keeping default values
  firewall_network_rules_collection = var.firewall_network_rules

  # (Optional) specify the application rules for Azure Firewall
  # This is default values, do not need this if keeping default values
  firewall_application_rule_collection = var.firewall_application_rules

  # Private DNS Zone Settings
  # By default, Azure NoOps will create Private DNS Zones for Logging in Hub VNet.
  # If you do want to create addtional Private DNS Zones, 
  # add in the list of private_dns_zones to be created.
  # else, remove the private_dns_zones argument.
  private_dns_zones = var.hub_private_dns_zones

  # By default, this module will create a bastion host, 
  # and set the argument to `enable_bastion_host = false`, to disable the bastion host.
  enable_bastion_host                 = var.enable_bastion_host
  azure_bastion_host_sku              = var.azure_bastion_host_sku
  azure_bastion_subnet_address_prefix = var.azure_bastion_subnet_address_prefix

  # By default, this will apply resource locks to all resources created by this module.
  # To disable resource locks, set the argument to `enable_resource_locks = false`.
  enable_resource_locks = var.enable_resource_locks

  # Tags
  add_tags = local.hub_resources_tags # Tags to be applied to all resources
}

#############################
### Spoke Configuration   ###
#############################

// Resources for the Operations Spoke
module "mod_ops_network" {
  providers = { azurerm = azurerm.operations }
  source    = "azurenoops/overlays-management-spoke/azurerm"
  version   = ">= 2.0.0"

  # By default, this module will create a resource group, provide the name here
  # To use an existing resource group, specify the existing resource group name, 
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG.
  create_resource_group = true
  location              = var.location
  deploy_environment    = var.deploy_environment
  org_name              = var.org_name
  environment           = var.environment
  workload_name         = var.ops_name
  
  # Collect Spoke Virtual Network Parameters
  # Spoke network details to create peering and other setup
  hub_virtual_network_id          = module.mod_hub_network.virtual_network_id
  hub_firewall_private_ip_address = module.mod_hub_network.firewall_private_ip
  hub_storage_account_id          = module.mod_hub_network.storage_account_id

  # (Required) To enable Azure Monitoring and flow logs
  # pick the values for log analytics workspace which created by Spoke module
  # Possible values range between 30 and 730
  log_analytics_workspace_id           = module.mod_hub_network.managmement_logging_log_analytics_id
  log_analytics_customer_id            = module.mod_hub_network.managmement_logging_storage_account_workspace_id # this is a issue in management module, need to fix. This hould not have storage_account in the name
  log_analytics_logs_retention_in_days = 30

  # Provide valid VNet Address space for spoke virtual network.    
  virtual_network_address_space = var.ops_vnet_address_space # (Required)  Spoke Virtual Network Parameters

  # (Required) Specify if you are deploying the spoke VNet using the same hub Azure subscription
  is_spoke_deployed_to_same_hub_subscription = var.is_ops_spoke_deployed_to_same_hub_subscription

  # (Required) Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # Route_table and NSG association to be added automatically for all subnets listed here.
  # subnet name will be set as per Azure naming convention by defaut. expected value here is: <App or project name>
  spoke_subnets = var.ops_subnets

  # Enable Flow Logs
  # By default, this will enable flow logs for all subnets.
  enable_traffic_analytics = var.enable_traffic_analytics

  # By default, forced tunneling is enabled for the spoke.
  # If you do not want to enable forced tunneling on the spoke route table, 
  # set `enable_forced_tunneling = false`.
  enable_forced_tunneling_on_route_table = var.enable_forced_tunneling_on_ops_route_table

  # Private DNS Zone Settings
  # By default, Azure NoOps will create Private DNS Zones for Logging in Hub VNet.
  # If you do want to create addtional Private DNS Zones, 
  # add in the list of private_dns_zones to be created.
  # else, remove the private_dns_zones argument.
  private_dns_zones = var.ops_private_dns_zones

  # Peering
  # By default, Azure NoOps will create peering between Hub and Spoke.
  # Since is using a gateway, set the argument to `use_source_remote_spoke_gateway = true`, to enable gateway traffic.   
  use_source_remote_spoke_gateway = var.use_source_remote_spoke_gateway

  # By default, this will apply resource locks to all resources created by this module.
  # To disable resource locks, set the argument to `enable_resource_locks = false`.
  enable_resource_locks = var.enable_resource_locks

  # Tags
  add_tags = local.operations_resources_tags # Tags to be applied to all resources
}

// Resources for the Shared Services Spoke
module "mod_svcs_network" {  
  providers = { azurerm = azurerm.sharedservices }
  source    = "azurenoops/overlays-management-spoke/azurerm"
  version   = ">= 2.0.0"

  # By default, this module will create a resource group, provide the name here
  # To use an existing resource group, specify the existing resource group name, 
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG.
  create_resource_group = true
  location              = var.location
  deploy_environment    = var.deploy_environment
  org_name              = var.org_name
  environment           = var.environment
  workload_name         = var.svcs_name

  # Collect Spoke Virtual Network Parameters
  # Spoke network details to create peering and other setup
  hub_virtual_network_id          = module.mod_hub_network.virtual_network_id
  hub_firewall_private_ip_address = module.mod_hub_network.firewall_private_ip
  hub_storage_account_id          = module.mod_hub_network.storage_account_id

  # (Required) To enable Azure Monitoring and flow logs
  # pick the values for log analytics workspace which created by Spoke module
  # Possible values range between 30 and 730
  log_analytics_workspace_id           = module.mod_hub_network.managmement_logging_log_analytics_id
  log_analytics_customer_id            = module.mod_hub_network.managmement_logging_storage_account_workspace_id # this is a issue in management module, need to fix
  log_analytics_logs_retention_in_days = 30

  # Provide valid VNet Address space for spoke virtual network.    
  virtual_network_address_space = var.svcs_vnet_address_space # (Required)  Spoke Virtual Network Parameters

  # (Required) Specify if you are deploying the spoke VNet using the same hub Azure subscription
  is_spoke_deployed_to_same_hub_subscription = var.is_svcs_spoke_deployed_to_same_hub_subscription

  # (Required) Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # Route_table and NSG association to be added automatically for all subnets listed here.
  # subnet name will be set as per Azure naming convention by defaut. expected value here is: <App or project name>
  spoke_subnets = var.svcs_subnets

  # Enable Flow Logs
  # By default, this will enable flow logs for all subnets.
  enable_traffic_analytics = var.enable_traffic_analytics

  # By default, forced tunneling is enabled for the spoke.
  # If you do not want to enable forced tunneling on the spoke route table, 
  # set `enable_forced_tunneling = false`.
  enable_forced_tunneling_on_route_table = var.enable_forced_tunneling_on_svcs_route_table

  # Private DNS Zone Settings
  # By default, Azure NoOps will create Private DNS Zones for Logging in Hub VNet.
  # If you do want to create addtional Private DNS Zones, 
  # add in the list of private_dns_zones to be created.
  # else, remove the private_dns_zones argument.
  private_dns_zones = var.svcs_private_dns_zones

  # Peering
  # By default, Azure NoOps will create peering between Hub and Spoke.
  # Since is using a gateway, set the argument to `use_source_remote_spoke_gateway = true`, to enable gateway traffic.   
  use_source_remote_spoke_gateway = var.use_source_remote_spoke_gateway

  # By default, this will apply resource locks to all resources created by this module.
  # To disable resource locks, set the argument to `enable_resource_locks = false`.
  enable_resource_locks = var.enable_resource_locks

  # Tags
  add_tags = local.sharedservices_resources_tags # Tags to be applied to all resources
}


