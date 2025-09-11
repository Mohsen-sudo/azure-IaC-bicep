@description('The resource ID of the local VNet')
param localVnetId string

@description('The resourceId of the remote VNet to peer with')
param peerVnetId string

@description('Peering name (must be unique per VNet)')
param peeringName string

@description('Whether to allow forwarded traffic')
param allowForwardedTraffic bool = true

@description('Whether to allow gateway transit')
param allowGatewayTransit bool = false

@description('Whether to use remote gateways')
param useRemoteGateways bool = false

// Extract the local VNet name from its resourceId
var localVnetName = last(split(localVnetId, '/'))

resource localVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: localVnetName
}

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: peeringName
  parent: localVnet
  properties: {
    remoteVirtualNetwork: {
      id: peerVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

output peeringId string = vnetPeering.id
