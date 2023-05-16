# Deploy the Landing Zone - Operations Managmement Spoke Virtual Network

The following will be created:

* Resource Groups for Spoke Networking
* Spoke Networks (Operations)

Review and if needed, comment out and modify the variables within the "Landing Zone Configuration" section under "Operations Management Spoke Virtual Network" of the common variable definitons file [parameters.tfvars](./tfvars/parameters.tfvars). Do not modify if you plan to use the default values.

Sample:

```bash

################################
# Landing Zone Configuration  ##
################################

####################################################
# 5d Operations Management Spoke Virtual Network ###
####################################################

ops_name                                       = "ops-core"
ops_vnet_address_space                         = ["10.8.6.0/24"]
ops_subnets                                    = {
  default = {
    name                                       = "ops-core"
    address_prefixes                           = ["10.8.6.224/27"]
    service_endpoints                          = ["Microsoft.Storage"]
    private_endpoint_network_policies_enabled  = false
    private_endpoint_service_endpoints_enabled = true
  }
}
ops_private_dns_zones                          = []
enable_forced_tunneling_on_ops_route_table     = true
is_ops_spoke_deployed_to_same_hub_subscription = true

```

After Modifying the variables, move on to Landing-Zone-Shared Services Management Spoke.

### Next step

:arrow_forward: [Deploy the Shared Services](./05e-Landing-Zone-Shared-Services-Spoke-Network.md)
