param location string
param addressPrefixes array
param subnetAddressPrefix string
param vnetName string = 'vnet-companyA' // Default; override for Company B in main.bicep

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
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
output vnetId string = vnet.id
output vnetName string = vnet.name
