@description('Location for Key Vault')
param location string
@description('Vault name')
param vaultName string

resource kv 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: vaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableSoftDelete: true
  }
}

output keyVaultId string = kv.i
