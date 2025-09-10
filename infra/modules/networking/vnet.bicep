@description('Azure location for the VNet')
param location string

@description('Address prefixes for the VNet')
param addressPrefixes array

@description('Name of the VNet')
param vnetName string = 'vnet-companyA'

@description('NAT Gateway resource id (optional)')
param natGatewayId string = ''

@description('DNS servers for the VNet (AADDS IPs only recommended)')
param dnsServers array = [
  '10.0.10.4'
  '10.0.10.5'
]

// AADDS subnet address prefixes (parameterize for flexibility)
@description('Address prefix for addsSubnetA')
param addsSubnetAAddressPrefix string = '10.0.1.0/24'

@description('Address prefix for addsSubnetB')
param addsSubnetBAddressPrefix string = '10.0.2.0/24'

@description('Address prefix for AVD subnet')
param avdSubnetAddressPrefix string = '10.0.3.0/24'

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
  name: 'adds-subnetA'
  parent: vnet
  properties: {
    addressPrefix: addsSubnetAAddressPrefix
  }
}

resource addsSubnetB 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: 'adds-subnetB'
  parent: vnet
  properties: {
    addressPrefix: addsSubnetBAddressPrefix
  }
}

resource avdSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: 'subnet-avd'
  parent: vnet
  properties: union({
    addressPrefix: avdSubnetAddressPrefix
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
