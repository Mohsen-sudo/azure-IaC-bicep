param location string
param addressPrefixes array
param subnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2024-10-01' = {
  name: 'vnet-companyA'
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
