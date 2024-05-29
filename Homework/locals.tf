locals {
 rules_csv = csvdecode(file(var.rules_file))
  vnet_ids = {
    for vnet_key, vnet_val in azurerm_virtual_network.vnets :
    vnet_key => [for subnet in vnet_val.subnet : subnet.id]
  }
  vnet_name = keys(local.vnet_ids)
  subnet_id = values(local.vnet_ids)
  subnet_ids = flatten(local.subnet_id)

  nsg_count = length(local.subnet_ids)
  nsg_names = [for i in range (local.nsg_count) : "subnet-nsg${i+1}"]

  nsg_id = values({ for nsg_name , value in values(azurerm_network_security_group.nsg): nsg_name => value.id})
  nsg_subnet = zipmap(local.subnet_ids , local.nsg_id)
  

}

# local.vnet_name --> ["vnet1" , "vnet2"]
# local.subnet_id --> [ [subnet1.id , subnet2.id] , [subnet1.id , subnet2.id] ]
# local.subnet_ids --> [ subnet1.id , subnet2.id , subnet1.id , subnet2.id ]
# flatten([[1,2] , [3,4] , [5,6]) --> [ 1,2,3,4,5,6]
# local.nsg_names --> ["subnet-nsg1","subnet-nsg2","subnet-nsg3", "subnet-nsg4"]
# local.nsg_id --> [nsg1.id , nsg2.id , nsg3.id , nsg4.id]

# local.nsg_id --> key --> 0 ,1 , 2 , 3
# local.nsg_id --> value --> [nsg1.id , nsg2.id , nsg3.id , nsg4.id]