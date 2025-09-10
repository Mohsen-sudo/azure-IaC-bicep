@description('Azure region')
param location string = 'northeurope'

@description('CompanyA Spoke VNet address prefix')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Subnet address prefix for AVD hosts')
param subnetAddressPrefix string = '10.1.1.0/24'

@description('Admin username for session hosts')
param adminUsername string
@secure()
@description('Admin password')
param adminPassword string

@description('Max session hosts in pool 01')
param maxSessionHostsPool01 int = 2

@description('Max session hosts in pool 02')
param maxSessionHostsPool02 int = 2

@description('Short prefix for AVD session host computer name')
param sessionHostPrefix string = 'cmpA-avd'

@description('Storage account name for FSLogix profiles')
param storageAccountName string = 'companyastorage'

@description('Private DNS Zone resource ID for privatelink.file.core.windows.net')
param privateDnsZoneId string = ''

@description('Hub VNet resource ID for peering')
param hubVnetId string

@description('Optional: Deploy NSG')
param deployNsg bool = true

@description('Optional: Deploy custom route table')
param deployRouteTable bool = false

@description('Custom routes for the route table (if used)')
param customRoutes array = []

// Create CompanyA spoke VNet with ONE subnet for AVD hosts
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'companyA-avd-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: 'avd-subnet'
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

// Optional: NSG for subnet
resource avdNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = if (deployNsg) {
  name: 'companyA-avd-nsg'
  location: location
  properties: {
    securityRules: [
      // Example: allow RDP from trusted IP (customize as needed)
      {
        name: 'AllowRDP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Associate NSG to subnet
resource subnetNsgAssoc 'Microsoft.Network/virtualNetworks/subnets/networkSecurityGroups@2023-09-01' = if (deployNsg) {
  name: 'avd-subnet-nsg-assoc'
  parent: vnet
  scope: vnet
  properties: {
    networkSecurityGroup: {
      id: avdNsg.id
    }
  }
  dependsOn: [
    vnet
    avdNsg
  ]
}

// Optional: Route table for subnet
resource avdRouteTable 'Microsoft.Network/routeTables@2023-09-01' = if (deployRouteTable) {
  name: 'companyA-avd-rt'
  location: location
  properties: {
    routes: customRoutes
  }
}

// Associate route table to subnet
resource subnetRtAssoc 'Microsoft.Network/virtualNetworks/subnets/routeTables@2023-09-01' = if (deployRouteTable) {
  name: 'avd-subnet-rt-assoc'
  parent: vnet
  scope: vnet
  properties: {
    routeTable: {
      id: avdRouteTable.id
    }
  }
  dependsOn: [
    vnet
    avdRouteTable
  ]
}

// Storage Account for FSLogix profiles
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {}
}

// Private Endpoint for Azure Files (FSLogix)
resource fslogixPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (privateDnsZoneId != '') {
  name: 'companyA-fslogix-pe'
  location: location
  properties: {
    subnet: { id: vnet.properties.subnets[0].id }
    privateLinkServiceConnections: [
      {
        name: 'fslogix-files'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: ['file']
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
            actionsRequired: ''
          }
        }
      }
    ]
    customDnsConfigs: [
      {
        name: 'privatelink.file.' + environment().suffixes.storage
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// VNet Peering to Hub
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: 'companyA-to-hub-peering'
  parent: vnet
  properties: {
    remoteVirtualNetwork: { id: hubVnetId }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

// Example AVD Host Pool 01 (resource reference, you can replace with your AVD module)
resource avdHostpool01 'Microsoft.DesktopVirtualization/hostPools@2022-02-10-preview' = {
  name: 'companyA-avd-hostpool01'
  location: location
  properties: {
    friendlyName: 'CompanyA-HostPool01'
    hostPoolType: 'Pooled'
    validationEnvironment: false
  }
}

// Example AVD Host Pool 02
resource avdHostpool02 'Microsoft.DesktopVirtualization/hostPools@2022-02-10-preview' = {
  name: 'companyA-avd-hostpool02'
  location: location
  properties: {
    friendlyName: 'CompanyA-HostPool02'
    hostPoolType: 'Pooled'
    validationEnvironment: false
  }
}
