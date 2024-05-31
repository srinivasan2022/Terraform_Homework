<!-- BEGIN_TF_DOCS -->
# Terraform IaC Azure VNET, Subnet, NSG and Association automation

### Steps :
- 1.Use Data Block for Resource Group
- 2.First we have to create the Two Vnets.
- 3.Each Vnet has Two subnets.
- 4.The Subnet prefixes are calculated from Vnet range using cidrsubnet() function.
- 5.Then , we create the Network Security Rule and Dynamic Rules for NSG.
- 6.Finally , we have to associate the NSG for respective subnets.

 ## Architecture Diagram :

 ![Homework](https://github.com/srinivasan2022/Terraform_Homework/assets/118502121/678b71fd-d90b-4ea5-8549-061aae72a3b8)

 ### Summary :
#### provider.tf : 
The Terraform code configures the Azure Resource Manager (AzureRM) provider, ensuring compatibility with version 3.0.2, and requires Terraform version 1.1.0 or higher. It initializes the Azure provider to manage Azure resources within Terraform scripts.
#### variable.tf
The code defines two variables for a Terraform configuration. The vnets variable is a map of virtual networks, each with an address space and a list of subnets specified by their name, newbits, and netnum. The rules_file variable is a string that defaults to "rules.csv", likely referencing an external file containing rules for further configuration.
#### main.tf
The provided Terraform code sets up Azure virtual networks, network security groups (NSGs), and their associations using a resource group named "Seenu_TF_RG." The azurerm_virtual_network resource creates multiple virtual networks based on the vnets variable, each with dynamic subnets. The azurerm_network_security_group resource creates multiple NSGs, applying dynamic security rules parsed from a local CSV file. Finally, the azurerm_subnet_network_security_group_association resource associates the NSGs with the subnets, using a flattened list of subnet IDs and a local mapping of NSG names.
#### locals.tf
The provided Terraform code defines local values to manage the configuration of Azure resources. It reads and decodes a CSV file of security rules, generates a list of virtual network IDs and subnet IDs, and creates a list of NSG names based on the number of subnets. The nsg_names list dynamically generates names for the NSGs to be associated with each subnet.


```hcl
# 1.Use Data Block for Resource Group
data "azurerm_resource_group" "rg" {
  name = "Seenu_TF_RG"
}

# 2.Creates Two Vnets with Address Space
resource "azurerm_virtual_network" "vnets" {
  for_each = var.vnets

  name = each.key
  address_space = [each.value.address_space]
  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location

  dynamic "subnet" {
    for_each = each.value.Subnets

    content {
      name = each.value.Subnets[subnet.key].name
      address_prefix = cidrsubnet(each.value.address_space , each.value.Subnets[subnet.key].newbits , each.value.Subnets[subnet.key].netnum)
      # 3.Subnet prefixes are calculated from Vnet range using cidrsubnet() function 
    }
  }
  depends_on = [ data.azurerm_resource_group.rg ]

}

# 4.Creates the Network Security Group for Each Subnet
resource "azurerm_network_security_group" "nsg" {       
  for_each =  toset(local.nsg_names)
  name = each.key
  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location

  dynamic "security_rule" {   # 5.Creates the NSG Rule and Applied rules for all NSG                            
     for_each = { for rule in local.rules_csv : rule.name => rule }
     content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
  depends_on = [ azurerm_virtual_network.vnets ]
}

# 6.Associate the NSG for respective Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_ass" {
  for_each = { for idx, subnet_id in flatten([for vnet in local.vnet_ids : vnet]) : idx => subnet_id }

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.nsg[local.nsg_names[each.key]].id
  depends_on = [ azurerm_network_security_group.nsg , azurerm_virtual_network.vnets]
}

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.1.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.0.2)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.0.2)

## Resources

The following resources are used by this module:

- [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) (resource)
- [azurerm_subnet_network_security_group_association.nsg_ass](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) (resource)
- [azurerm_virtual_network.vnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_rules_file"></a> [rules\_file](#input\_rules\_file)

Description: n/a

Type: `string`

Default: `"rules.csv"`

### <a name="input_vnets"></a> [vnets](#input\_vnets)

Description: n/a

Type:

```hcl
map(object({
      address_space = string
      Subnets = list(object({
        name = string
        newbits = number
        netnum = number
      }))
  }))
```

Default:

```json
{
  "vnet1": {
    "Subnets": [
      {
        "name": "subnet1",
        "netnum": 1,
        "newbits": 8
      },
      {
        "name": "subnet2",
        "netnum": 2,
        "newbits": 8
      }
    ],
    "address_space": "10.1.0.0/16"
  },
  "vnet2": {
    "Subnets": [
      {
        "name": "subnet1",
        "netnum": 1,
        "newbits": 8
      },
      {
        "name": "subnet2",
        "netnum": 2,
        "newbits": 8
      }
    ],
    "address_space": "10.2.0.0/16"
  }
}
```

## Outputs

No outputs.

## Modules

No modules.

We completed our Terraform Homework.
<!-- END_TF_DOCS -->