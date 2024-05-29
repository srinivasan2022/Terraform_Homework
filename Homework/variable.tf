variable "vnets" {
  type = map(object({
      address_space = string
      Subnets = list(object({
        name = string
        newbits = number
        netnum = number
      })) 
  }))

  default = {
    vnet1 = {
      address_space = "10.1.0.0/16"
      Subnets = [
        {name = "subnet1" , newbits = 8 , netnum = 1},
        {name = "subnet2" , newbits = 8 , netnum = 2}
      ]
    },

    vnet2 = {
       address_space = "10.2.0.0/16"
       Subnets = [
        {name = "subnet1" , newbits = 8 , netnum = 1},
        {name = "subnet2" , newbits = 8 , netnum = 2}
       ]
    }
  }
}

variable "rules_file" {
    type = string
    default = "rules.csv"
  
}