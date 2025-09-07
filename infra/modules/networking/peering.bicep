@description('The name of the Network Security Group')
param nsgName string
@description('Location for the NSG')
param location string
@description('Optional: Array of additional custom security rules')
param customRules array = []

var baseSecurityRules = [
  // ... previous rules unchanged ...
  {
    name: 'Allow-AVD-Agent-443'
    properties: {
      priority: 210
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
      priority: 211
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
      priority: 212
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '9350'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
    }
  }
  // ... rest unchanged ...
]

// Merge base and custom rules
var securityRules = baseSecurityRules ++ customRules

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
}

output nsgId string = nsg.id
