targetScope = 'resourceGroup'

@description('Deployment location for all resources')
param location string

@description('Admin username for shared services')
param adminUsername string

@description('Admin password for shared services')
param adminPassword string

@description('Address prefixes for the hub virtual network')
param vnetAddressPrefixes array

@description('Address prefix for the hub subnet')
param subnetAddressPrefix string

@description('Maximum number of session hosts')
param maxSessionHosts int

@description('Deployment timestamp')
param timestamp string

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'hubVnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
      {
        name: 'hubSubnet'
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource hubKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'sharedServicesKV25momo' // <-- your Key Vault name!
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    enableRbacAuthorization: true
    // Optionally, you could use adminUsername/adminPassword as secrets here if desired
  }
}

output vnetId string = hubVnet.id
output subnetId string = hubVnet.properties.subnets[0].id
output keyVaultId string = hubKeyVault.id
