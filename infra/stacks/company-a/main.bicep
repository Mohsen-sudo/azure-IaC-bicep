@description('Azure region')
param location string = 'northeurope'

@description('CompanyA Spoke VNet address prefix')
param vnetAddressPrefix string = '10.2.0.0/16'

@description('Subnet address prefix for the AVD subnet')
param subnetAddressPrefix string = '10.2.1.0/24'

@description('Storage account name for FSLogix profiles')
param storageAccountName string = 'companyastorage'

@description('Private DNS Zone resource ID for privatelink.file.core.windows.net')
param privateDnsZoneId string = ''

@description('Admin username for session host VM')
param adminUsername string

@description('Admin password for session host VM')
@secure()
param adminPassword string

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
        fqdn: 'privatelink.file.${environment().suffixes.storage}'
      }
    ]
  }
}

// Example AVD Host Pool - FIRST
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

// Second AVD Host Pool - placed immediately after the first
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

// NIC for session host VM
resource sessionHostNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'companyA-sessionhost-01-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: vnet.properties.subnets[0].id }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Session host VM (AAD-joined)
resource sessionHostVM 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: 'companyA-sessionhost-01'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: 'companyA-sessionhost-01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        // To enable AAD join, you need to use VM extension (see below)
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-10'
        sku: 'win10-21h2-avd'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Standard_LRS' }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: sessionHostNic.id }
      ]
    }
  }
}

// Azure AD Join using VM Extension (required for AAD join)
resource aadJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: 'companyA-sessionhost-01/aadlogin'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    sessionHostVM
  ]
}
