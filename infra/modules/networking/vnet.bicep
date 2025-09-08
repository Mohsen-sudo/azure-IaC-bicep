param location string
param addressPrefixes array
param subnetAddressPrefix string
param vnetName string = 'vnet-companyA' // Default; override for Company B in main.bicep
param natGatewayId string = '' // <-- NEW: Optional NAT Gateway id for outbound connectivity

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: 'subnet-avd'
        properties: union({
          addressPrefix: subnetAddressPrefix
        }, !empty(natGatewayId) ? {
          natGateway: {
            id: natGatewayId
          }
        } : {})
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetName string = vnet.properties.subnets[0].name
