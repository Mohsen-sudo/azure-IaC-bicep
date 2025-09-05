// shared-services/main.bicep
// Deploy Hub VNet + Key Vault for shared services

targetScope = 'resourceGroup'

@description('Deployment location for all resources')
param location string

@description('Virtual Network address prefixes')
param vnetAddressPrefixes array

@description('Subnet address prefix')
param subnetAddressPrefix string

@description('Key Vault name')
param keyVaultName string

// ========== Virtual Network ==========
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'hubVNet'
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

// ========== Key Vault ==========
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
  }
}

// ========== Outputs ==========
output vnetId string = hubVnet.id
output subnetId string = hubVnet.properties.subnets[0].id
output keyVaultId string = kv.id
