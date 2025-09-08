@description('Name of the NAT Gateway')
param natGatewayName string = 'avd-natgw'

@description('Location for NAT Gateway and resources')
param location string = resourceGroup().location

@description('Name of the public IP for NAT Gateway')
param publicIpName string = 'avd-natgw-pip'

@description('Name of the Virtual Network')
param vnetName string

@description('Name of the subnet to attach NAT Gateway')
param subnetName string

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

// Get existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

// Get existing subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}

// Attach NAT Gateway to subnet
resource natSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnet.properties.addressPrefix
    natGateway: {
      id: natGateway.id
    }
    // Preserve existing NSG, route table, etc. if present
    networkSecurityGroup: subnet.properties.networkSecurityGroup
    routeTable: subnet.properties.routeTable
  }
}
