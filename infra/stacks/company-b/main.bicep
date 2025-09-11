@description('Azure region')
param location string = 'northeurope'

@description('Spoke VNet address prefix')
param vnetAddressPrefix string = '10.2.0.0/16'

@description('Subnet address prefix for AVD subnet')
param subnetAddressPrefix string = '10.2.1.0/24'

@description('Storage account name for FSLogix profiles')
param storageAccountName string = 'companybstorage'

@description('Private DNS Zone resource ID for privatelink.file.core.windows.net')
param privateDnsZoneId string = ''

// NSG rules
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
  {
    name: 'AllowAVDOutbound'
    properties: {
      priority: 2000
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      direction: 'Outbound'
    }
  }
]

// Optional: Route table
var customRoutes = []

// Network Security Group
resource avdNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'companyB-avd-nsg'
  location: location
  properties: {
    securityRules: nsgRules
  }
}

// Route Table
resource avdRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'companyB-avd-rt'
  location: location
  properties: {
    routes: customRoutes
  }
}

// VNet + Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'companyB-avd-vnet'
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

// Private Endpoint for FSLogix
resource fslogixPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (privateDnsZoneId != '') {
  name: 'companyB-fslogix-pe'
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
  }
}

// Link PE to Private DNS Zone
resource fslogixDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (privateDnsZoneId != '') {
  name: 'filesDnsGroup'
  parent: fslogixPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'filesDnsConfig'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// AVD Host Pools only (no VMs)
resource avdHostpool01 'Microsoft.DesktopVirtualization/hostPools@2022-02-10-preview' = {
  name: 'companyB-avd-hostpool01'
  location: location
  properties: {
    friendlyName: 'CompanyB-HostPool01'
    hostPoolType: 'Pooled'
    validationEnvironment: false
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
  }
}

resource avdHostpool02 'Microsoft.DesktopVirtualization/hostPools@2022-02-10-preview' = {
  name: 'companyB-avd-hostpool02'
  location: location
  properties: {
    friendlyName: 'CompanyB-HostPool02'
    hostPoolType: 'Pooled'
    validationEnvironment: false
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
  }
}
