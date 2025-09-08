param location string
param addressPrefixes array
param subnetAddressPrefix string
param vnetName string = 'vnet-companyA'
param natGatewayId string = ''
param dnsServers array = [
  '10.0.10.5'
  '168.63.129.16'
]

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    dhcpOptions: {
      dnsServers: dnsServers
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
