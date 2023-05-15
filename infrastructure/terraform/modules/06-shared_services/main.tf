# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*  
SUMMARY:  Module to deploy a Key Vault to the Shared Services Network
DESCRIPTION: This module deploys a Bastion Jumpbox and Shared Key Vault to the Shared Services Network
AUTHOR/S: jspinella
*/

###############################
## Key Vault Configuration  ###
###############################
module "mod_shared_keyvault" {
  source  = "azurenoops/overlays-key-vault/azurerm"
  version = "~> 1.0.2"

  # By default, this module will create a resource group and 
  # provide a name for an existing resource group. If you wish 
  # to use an existing resource group, change the option 
  # to "create_key_vault_resource_group = false."   
  existing_resource_group_name = data.terraform_remote_state.landing_zone.outputs.svcs_resource_group_name
  location                     = local.default_location
  deploy_environment           = local.deploy_environment
  org_name                     = local.org_name
  environment                  = local.environment
  workload_name                = "keys"

  # This is to enable the features of the key vault
  enabled_for_deployment          = local.enabled_for_deployment
  enabled_for_disk_encryption     = local.enabled_for_disk_encryption
  enabled_for_template_deployment = local.enabled_for_template_deployment

  # This is to enable the network access to the key vault
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  # Creating Private Endpoint requires, VNet name to create a Private Endpoint
  # By default this will create a `privatelink.vaultcore.azure.net` DNS zone. if created in commercial cloud
  # To use existing subnet, specify `existing_subnet_id` with valid subnet id. 
  # To use existing private DNS zone specify `existing_private_dns_zone` with valid zone name
  # Private endpoints doesn't work If not using `existing_subnet_id` to create key vault inside a specified VNet.
  enable_private_endpoint   = local.enable_private_endpoint
  existing_subnet_id        = data.azurerm_subnet.svcs_subnet.id
  virtual_network_name      = data.terraform_remote_state.landing_zone.outputs.svcs_virtual_network_name
  existing_private_dns_zone = azurerm_private_dns_zone.dns_zone.name

  # Current user should be here to be able to create keys and secrets
  admin_objects_ids = [
    data.azuread_group.admin_group.id
  ]

  # This is to enable resource locks for the key vault. 
  enable_resource_locks = local.enable_resource_locks

  # Tags for Azure Resources
  add_tags = local.sharedservices_resources_tags
}

#####################################
## Bastion Jumpbox Configuration  ###
#####################################

/* resource "azurerm_network_interface" "bastion_jumpbox_nic" {
  count               = local.enable_bastion_host ? 1 : 0
  name                = data.azurenoopsutils_resource_name.bastion_nic.result
  location            = module.mod_azure_region_lookup.location_cli
  resource_group_name = data.terraform_remote_state.landing_zone.outputs.svcs_resource_group_name

  ip_configuration {
    name                          = "bastion-jumpbox-ipconfig"
    subnet_id                     = data.terraform_remote_state.landing_zone.outputs.svcs_default_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "bastion_jumpbox_vm" {
  count                           = local.enable_bastion_host ? 1 : 0
  name                            = data.azurenoopsutils_resource_name.bastion_vm.result
  resource_group_name             = data.terraform_remote_state.landing_zone.outputs.svcs_resource_group_name
  location                        = module.mod_azure_region_lookup.location_cli
  size                            = "Standard_F2"
  admin_username                  = "mpeadminuser"
  disable_password_authentication = false
  admin_password                  = "P@ssw0rd1234"
  network_interface_ids = [
    azurerm_network_interface.bastion_jumpbox_nic.0.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
} */