@description('Azure region')
param location string = 'northeurope'

@description('CompanyA Spoke VNet address prefix')
param vnetAddressPrefix string = 'vnetAddressPrefix'

@description('Storage account name for FSLogix profiles')
param storageAccountName string = 'companyastorage'

@description('Private DNS Zone resource ID for privatelink.file.core.windows.net')
param privateDnsZoneId string = ''

@description('Hub VNet resource ID for peering')
param hubVnetId string

// Optional: NSG for subnet
var nsgRules = [
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

resource avdNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'companyA-avd-nsg'
  location: location
  properties: {
    securityRules: nsgRules
  }
}

// Optional: Route table for subnet
var customRoutes = []

resource avdRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'companyA-avd-rt'
  location: location
  properties: {
    routes: customRoutes
  }
}

// Create CompanyA spoke VNet with ONE subnet for AVD hosts, associate NSG and route table directly in subnet properties
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
          networkSecurityGroup: { id: avdNsg.id }
          routeTable: { id: avdRouteTable.id }
        }
      }
    ]
  }
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
        name: 'privatelink.file.${environment().suffixes.storage}'
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

// Example AVD Host Pool 01 (replace with your module if needed)
resource avdHostpool01 'Microsoft.DesktopVirtualization/hostPools@2022-02-10-preview' = {
  name: 'companyA-avd-hostpool01'
  location: location
  properties: {
    friendlyName: 'CompanyA-HostPool01'
    hostPoolType: 'Pooled'
    validationEnvironment: false
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
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
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
  }
}
