param location string
param vnetId string
param vpnPIPName string

// Public IP for VPN Gateway
resource vpnPIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: vpnPIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: 'sharedServicesVNetGateway'
  location: location
  properties: {
    sku: {
      name: 'VpnGw1'    // Required
      tier: 'VpnGw1'    // Required
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          publicIPAddress: {
            id: vpnPIP.id
          }
          subnet: {
            id: '${vnetId}/subnets/GatewaySubnet'
          }
        }
      }
    ]
  }
}

// Output
output vpnGatewayId string = vpnGateway.id
