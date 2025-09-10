@description('The name of the Network Security Group')
param nsgName string
@description('Location for the NSG')
param location string
@description('Optional: Array of additional custom security rules')
param customRules array = []

var baseSecurityRules = [
  // DNS (UDP & TCP)
  {
    name: 'Allow-ADDS-DNS-UDP'
    properties: {
      priority: 100
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Udp'
      sourcePortRange: '*'
      destinationPortRange: '53'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  {
    name: 'Allow-ADDS-DNS-TCP'
    properties: {
      priority: 101
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '53'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  // Kerberos (UDP & TCP)
  {
    name: 'Allow-ADDS-Kerberos-TCP'
    properties: {
      priority: 110
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '88'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  {
    name: 'Allow-ADDS-Kerberos-UDP'
    properties: {
      priority: 111
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Udp'
      sourcePortRange: '*'
      destinationPortRange: '88'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  // LDAP and LDAPS
  {
    name: 'Allow-ADDS-LDAP'
    properties: {
      priority: 120
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '389'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  {
    name: 'Allow-ADDS-LDAPS'
    properties: {
      priority: 121
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '636'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  // RPC Endpoint Mapper
  {
    name: 'Allow-ADDS-RPC-EPM'
    properties: {
      priority: 130
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '135'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  // RPC Dynamic Ports
  {
    name: 'Allow-ADDS-RPC-Dynamic'
    properties: {
      priority: 131
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '49152-65535'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  // SMB
  {
    name: 'Allow-ADDS-SMB'
    properties: {
      priority: 140
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '445'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  // Inbound for AD DS (repeat above for inbound if required, or rely on "Allow-Subnet-Internal")
  {
    name: 'Allow-Subnet-Internal'
    properties: {
      priority: 300
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '*'
    }
  }
  // RDP (Restrict source address in production!)
  {
    name: 'Allow-RDP-Inbound'
    properties: {
      priority: 400
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3389'
      sourceAddressPrefix: 'Internet' // Replace with your admin IP or range!
      destinationAddressPrefix: '*'
    }
  }
  // AVD Agent ports (Outbound)
  {
    name: 'Allow-AVD-Agent-443'
    properties: {
      priority: 410
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
    }
  }
  {
    name: 'Allow-AVD-Agent-9354'
    properties: {
      priority: 411
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '9354'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
    }
  }
  {
    name: 'Allow-AVD-Agent-9350'
    properties: {
      priority: 412
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '9350'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
    }
  }
  // Deny all catch-all
  {
    name: 'Deny-All-Inbound'
    properties: {
      priority: 4096
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'Deny-All-Outbound'
    properties: {
      priority: 4096
      direction: 'Outbound'
      access: 'Deny'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
    }
  }
]

var securityRules = concat(baseSecurityRules, customRules)

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
}

output nsgId string = nsg.id
