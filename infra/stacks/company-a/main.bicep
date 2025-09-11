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

@secure()
@description('Admin password for session host VM')
param adminPassword string

@description('Domain FQDN')
param domainName string = 'contoso.local'

@description('Domain Join Username')
param domainJoinUsername string

@secure()
@description('Domain Join Password')
param domainJoinPassword string

// Optional: NSG for subnet with inbound RDP and outbound virtual network access
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

// Optional: Route table for subnet
var customRoutes = []

resource avdNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'companyA-avd-nsg'
  location: location
  properties: {
    securityRules: nsgRules
  }
}

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
  }
}

// Link PE to private DNS zone
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

// Example AVD Host Pools
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

// ------ SESSION HOST VM SECTION ------

// Network Interface for VM
resource avdNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'companyA-avd-vm01-nic'
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
    networkSecurityGroup: { id: avdNsg.id }
  }
}

// Session Host VM for AVD
resource avdVm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: 'compA-vm01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: 'companyA-avd-vm01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: avdNic.id }
      ]
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
      }
    }
  }
}

// Domain Join Extension
resource domainJoin 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: 'joindomain'
  parent: avdVm
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      OUPath: ''
      User: domainJoinUsername
      Restart: true
      Options: 3
      Debug: true
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
}
