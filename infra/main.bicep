targetScope = 'resourceGroup'

@description('Deployment location for all resources')
param location string

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
  }
}

output vnetId string = hubVnet.id
output subnetId string = hubVnet.properties.subnets[0].id
output keyVaultId string = hubKeyVault.id
