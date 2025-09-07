@description('Location for peering')
param location string
@description('The resourceId of the local VNet')
param vnetId string
@description('The resourceId of the remote VNet to peer with')
param peerVnetId string

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: 'peer-to-hub'
  parent: vnetId
  location: location
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
