@description('Location of the resource')
param location string

@description('Name of the peering')
param peeringName string

@description('Source VNet ID')
param vnetId string

@description('Remote VNet ID')
param remoteVnetId string

@description('Allow forwarded traffic')
param allowForwardedTraffic bool = true

@description('Allow gateway transit')
param allowGatewayTransit bool = false

@description('Use remote gateways')
param useRemoteGateways bool = false

@description('Allow virtual network access')
param allowVirtualNetworkAccess bool = true

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: '${last(split(vnetId, '/'))}/${peeringName}'
  location: location
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
  }
}

output peeringId string = vnetPeering.id
