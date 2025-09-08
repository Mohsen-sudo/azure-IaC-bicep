@description('Name of the NAT Gateway')
param natGatewayName string = 'avd-natgw'

@description('Location for NAT Gateway and resources')
param location string

@description('Name of the public IP for NAT Gateway')
param publicIpName string = 'avd-natgw-pip'

// Public IP for NAT Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2021-05-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}

output natGatewayId string = natGateway.id
