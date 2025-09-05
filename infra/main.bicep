// Shared Services Hub Deployment
targetScope = 'resourceGroup'

@description('Location for all resources')
param location string = 'northeurope'

@description('Virtual network address space')
param vnetAddressPrefixes array = [
  '10.0.0.0/16'
]

@description('Subnet address prefix for the hub subnet')
param subnetAddressPrefix string = '10.0.0.0/24'

@description('Key Vault name')
param keyVaultName string = 'sharedServicesKV25MOHSEN'

// ========== Virtual Network ==========
resource hubVnet 'Microsoft.Network/virtualNetworks@2024-10-01' = {
  name: 'hubVnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
      {
        name: 'HubSubnet'
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

// ========== Outputs ==========
output vnetId string = hubVnet.id
output subnetId string = hubVnet.properties.subnets[0].id

// ========== Key Vault ==========
resource hubKV 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [] // Add access policies as needed
    enableSoftDelete: true
    enablePurgeProtection: true
  }
}
