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

# { for idx, subnet_id in flatten([for vnet in local.vnet_ids : vnet]) : idx => subnet_id } -->
# {
#   "0" = "/subscriptions/bd7a3996-9bc3-4c7a-8038-220d4ea0cea8/resourceGroups/Seenu_TF_RG/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/subnet1"
#   "1" = "/subscriptions/bd7a3996-9bc3-4c7a-8038-220d4ea0cea8/resourceGroups/Seenu_TF_RG/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/subnet2"
#   "2" = "/subscriptions/bd7a3996-9bc3-4c7a-8038-220d4ea0cea8/resourceGroups/Seenu_TF_RG/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/subnet1"
#   "3" = "/subscriptions/bd7a3996-9bc3-4c7a-8038-220d4ea0cea8/resourceGroups/Seenu_TF_RG/providers/Microsoft.Network/virtualNetworks/vnet2/subnets/subnet2"
# }