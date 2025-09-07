@description('The name of the local VNet')
param vnetName string

@description('The resourceId of the remote VNet to peer with')
param peerVnetId string

resource localVnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: 'peer-to-hub'
  parent: localVnet
  properties: {
    remoteVirtualNetwork: {
      id: peerVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

output peeringId string = vnetPeering.id
