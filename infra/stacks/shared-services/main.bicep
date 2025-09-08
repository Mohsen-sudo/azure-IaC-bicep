targetScope = 'resourceGroup'

@description('Deployment location for all resources')
param location string
param adminUsername string
@secure()
param adminPassword string

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'hubVnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
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

// NSG for hubSubnet to allow DNS inbound
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

// Windows Server VM for DNS forwarder
resource dnsNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'dns-forwarder-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[0].id // hubSubnet
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource dnsVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'dns-forwarder'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    osProfile: {
      computerName: 'dns-forwarder'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: dnsNic.id
        }
      ]
    }
  }
}

resource hubKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'sharedServicesKV25momo'
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

// Public IP for VPN Gateway
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

// VPN Gateway
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
            id: hubVnet.properties.subnets[1].id // GatewaySubnet
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

output vnetId string = hubVnet.id
output hubSubnetId string = hubVnet.properties.subnets[0].id
output dnsVmPrivateIp string = dnsNic.properties.ipConfigurations[0].properties.privateIPAddress
output gatewaySubnetId string = hubVnet.properties.subnets[1].id
output addsSubnetAId string = hubVnet.properties.subnets[2].id
output addsSubnetBId string = hubVnet.properties.subnets[3].id
output keyVaultId string = hubKeyVault.id
output vpnGatewayId string = vpnGateway.id
output vpnGwPublicIPId string = vpnGwPublicIP.id
