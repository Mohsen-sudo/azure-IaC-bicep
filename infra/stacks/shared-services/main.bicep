targetScope = 'resourceGroup'

@description('Deployment location for all resources')
param location string

// =====================
// Network Security Group
// =====================
resource hubNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'hubSubnet-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-DNS-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-DNS-Inbound-TCP'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// =====================
// Hub Virtual Network
// =====================
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'hubVnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    dhcpOptions: {
      dnsServers: [
        '10.0.10.4'
        '10.0.10.5'
      ]
    }
    subnets: [
      {
        name: 'hubSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: hubNsg.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
        }
      }
      {
        name: 'ADDSSubnetA'
        properties: {
          addressPrefix: '10.0.10.0/24'
        }
      }
      {
        name: 'ADDSSubnetB'
        properties: {
          addressPrefix: '10.0.20.0/24'
        }
      }
    ]
  }
}

// =====================
// Subnet Symbolic Resources
// =====================
resource hubSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: hubVnet
  name: 'hubSubnet'
}
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: hubVnet
  name: 'GatewaySubnet'
}
resource addsSubnetA 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: hubVnet
  name: 'ADDSSubnetA'
}
resource addsSubnetB 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: hubVnet
  name: 'ADDSSubnetB'
}

// =====================
// Key Vault
// =====================
resource hubKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'sharedServicesKV-Mohsen'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    enableRbacAuthorization: true
  }
}

// =====================
// VPN Gateway
// =====================
resource vpnGwPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'hubVpnGatewayPIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = {
  name: 'hubVpnGateway'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'gwIpConfig'
        properties: {
          publicIPAddress: {
            id: vpnGwPublicIP.id
          }
          subnet: {
            id: gatewaySubnet.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
  }
}

// =====================
// Azure AD DS (FIXED API VERSION)
// =====================
resource azureADDS 'Microsoft.AAD/domainServices@2022-12-01' = {
  name: 'aadds-mohsen'
  location: location
  properties: {
    domainName: 'contoso.local'       // replace with your on-prem domain
    subnetId: addsSubnetA.id          // dedicated subnet for Azure AD DS
    sku: 'Standard'
    enableSecureLDAP: false           // enable later if required
    enableAzureResourceForest: false
  }
}

// =====================
// Outputs
// =====================
output vnetId string = hubVnet.id
output hubSubnetId string = hubSubnet.id
output gatewaySubnetId string = gatewaySubnet.id
output addsSubnetAId string = addsSubnetA.id
output addsSubnetBId string = addsSubnetB.id
output keyVaultId string = hubKeyVault.id
output vpnGatewayId string = vpnGateway.id
output vpnGwPublicIPId string = vpnGwPublicIP.id
output azureADDSId string = azureADDS.id
output azureADDSDomainName string = azureADDS.properties.domainName
output azureADDSSubnetId string = addsSubnetA.id
