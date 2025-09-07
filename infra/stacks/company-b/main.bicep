param adminUsername string
param location string
param vnetAddressPrefixes array
param subnetAddressPrefix string
param maxSessionHosts int

@description('Resource ID of Key Vault containing VM admin password')
param keyVaultResourceId string
@allowed([
  'CompanyBAdminPassword'
  'CompanyAAdminPassword'
])
param adminPasswordSecretName string = 'CompanyBAdminPassword'

// Deploy VNet
module vnet '../../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnetAddressPrefix: subnetAddressPrefix
    vnetName: 'vnet-companyB'
  }
}

// Deploy NSG
module nsg '../../modules/networking/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    nsgName: 'companyB-nsg'
    customRules: []
  }
}

// Deploy Peering
module peering '../../modules/networking/peering.bicep' = {
  name: 'peeringDeployment'
  params: {
    vnetName: vnet.outputs.vnetName
    peerVnetId: '/subscriptions/2323178e-8454-42b7-b2ec-fc8857af816e/resourceGroups/rg-shared-services/providers/Microsoft.Network/virtualNetworks/hubVnet'
  }
}

// Deploy Storage Account
module storage '../../modules/storage/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: 'companybstorage'
  }
}

// --- Key Vault secret fetch ---
resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: last(split(keyVaultResourceId, '/'))
  scope: resourceGroup(
    split(keyVaultResourceId, '/')[4], // Resource group name
    split(keyVaultResourceId, '/')[2]  // Subscription ID
  )
}

resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' existing = {
  parent: kv
  name: adminPasswordSecretName
}

var adminPassword = adminPasswordSecret.properties.value

// Deploy Hostpool
module hostpool '../../modules/avd/hostpool.bicep' = {
  name: 'hostpoolDeployment'
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    maxSessionHosts: maxSessionHosts
    subnetId: vnet.outputs.subnetId
    dnsServers: [
      '10.0.20.5'
      '10.0.20.4'
    ]
    storageAccountId: storage.outputs.storageAccountId
    keyVaultResourceId: keyVaultResourceId
    adminPasswordSecretName: adminPasswordSecretName
    domainName: ''
  }
}

// Deploy Workspace
module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}

// --- Debug outputs ---
output kvResourceIdDebug string = keyVaultResourceId
output kvSubIdDebug string = split(keyVaultResourceId, '/')[2]
output kvRgDebug string = split(keyVaultResourceId, '/')[4]
output kvNameDebug string = last(split(keyVaultResourceId, '/'))
output adminPasswordSecretValue string = adminPassword
output vnetName string = vnet.outputs.vnetName
output subnetId string = vnet.outputs.subnetId
output storageAccountId string = storage.outputs.storageAccountId
output hostPoolId string = hostpool.outputs.hostPoolId
output workspaceId string = workspace.outputs.workspaceId
