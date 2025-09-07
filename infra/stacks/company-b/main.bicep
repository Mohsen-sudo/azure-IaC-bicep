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

// Securely fetch the VM admin password from Key Vault at deployment time
var adminPassword = reference(keyVaultResourceId, '2018-02-14').secrets[adminPasswordSecretName]

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

// Deploy Hostpool (make sure all required params are provided)
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
    domainName: 'corp.mohsenlab.local'
    // companyPrefix, vmSize, vmImagePublisher, etc. will use defaults from module unless you override
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

// --- Debug outputs (no secrets!) ---
output kvResourceIdDebug string = keyVaultResourceId
output kvNameDebug string = last(split(keyVaultResourceId, '/'))
output adminPasswordSecretNameDebug string = adminPasswordSecretName
output vnetName string = vnet.outputs.vnetName
output subnetId string = vnet.outputs.subnetId
output storageAccountId string = storage.outputs.storageAccountId
output hostPoolId string = hostpool.outputs.hostPoolId
output workspaceId string = workspace.outputs.workspaceId
