@description('The name of the local VNet')
param vnetName string

@description('The resourceId of the remote VNet to peer with')
param peerVnetId string

@description('Whether to allow forwarded traffic')
param allowForwardedTraffic bool = true

@description('Whether to allow gateway transit')
param allowGatewayTransit bool = false

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
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: false
  }
}

output peeringId string = vnetPeering.id
