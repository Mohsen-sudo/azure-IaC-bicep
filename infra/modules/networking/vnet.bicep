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
  }
}

resource addsSubnetA 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${vnet.name}/adds-subnetA'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

resource addsSubnetB 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${vnet.name}/adds-subnetB'
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}

resource avdSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${vnet.name}/subnet-avd'
  properties: union({
    addressPrefix: '10.0.3.0/24'
  }, !empty(natGatewayId) ? {
    natGateway: {
      id: natGatewayId
    }
  } : {})
}

output addsSubnetAId string = addsSubnetA.id
output addsSubnetBId string = addsSubnetB.id
output avdSubnetId string   = avdSubnet.id
output vnetId string        = vnet.id
output vnetName string      = vnet.name
