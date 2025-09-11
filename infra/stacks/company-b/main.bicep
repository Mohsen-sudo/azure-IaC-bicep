@description('Azure region')
param location string = 'northeurope'

@description('CompanyB Spoke VNet address prefix')
param vnetAddressPrefix string = '10.3.0.0/16'

@description('Subnet address prefix for the AVD subnet')
param subnetAddressPrefix string = '10.3.1.0/24'

@description('Storage account name for FSLogix profiles')
param storageAccountName string = 'companybstorage'

@description('Private DNS Zone resource ID for privatelink.file.core.windows.net')
param privateDnsZoneId string = ''

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
  name: 'companyB-avd-nsg'
  location: location
  properties: {
    securityRules: nsgRules
  }
}

// Optional: Route table for subnet
var customRoutes = []

resource avdRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'companyB-avd-rt'
  location: location
  properties: {
    routes: customRoutes
  }
}

// Create CompanyB spoke VNet with ONE subnet for AVD hosts
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

// Private Endpoint for Azure Files (FSLogix)
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
    customDnsConfigs: [
      {
        fqdn: 'privatelink.file.${environment().suffixes.storage}'
      }
    ]
  }
}

// Example AVD Host Pool - FIRST
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

// Second AVD Host Pool - placed immediately after the first
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
