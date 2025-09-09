param location string
param addressPrefixes array
param vnetName string = 'vnet-companyA'
param natGatewayId string = ''
param dnsServers array = [
  '10.0.10.4'
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
        name: 'adds-subnetA'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'adds-subnetB'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'subnet-avd'
        properties: union({
          addressPrefix: '10.0.3.0/24'
        }, !empty(natGatewayId) ? {
          natGateway: {
            id: natGatewayId
          }
        } : {})
      }
    ]
  }
}

output addsSubnetAId string = vnet.properties.subnets[0].id
output addsSubnetBId string = vnet.properties.subnets[1].id
output avdSubnetId string = vnet.properties.subnets[2].id
output vnetId string = vnet.id
output vnetName string = vnet.name
