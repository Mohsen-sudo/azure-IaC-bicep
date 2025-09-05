// Shared Services VNet and Key Vault

param location string
param vnetAddressPrefixes array
param subnetAddressPrefix string

// ========== Virtual Network ==========
resource vnet 'Microsoft.Network/virtualNetworks@2024-10-01' = {
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
param vaultName string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [] // can add SPN access here later
  }
}

// ========== Outputs ==========
output subnetId string = vnet.properties.subnets[0].id
output vnetId string = vnet.id
output keyVaultId string = kv.id
