param adminUsername string
param location string
param vnetAddressPrefixes array
param subnetAddressPrefix string
param maxSessionHosts int

@description('Resource ID of Key Vault containing VM admin password')
param keyVaultResourceId string
@allowed([
  'CompanyAAdminPassword'
  'CompanyBAdminPassword'
])
param adminPasswordSecretName string = 'CompanyAAdminPassword'

module vnet '../../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnetAddressPrefix: subnetAddressPrefix
    vnetName: 'vnet-companyA'
  }
}

module nsg '../../modules/networking/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    nsgName: 'companyA-nsg'
    customRules: []
  }
}

module peering '../../modules/networking/peering.bicep' = {
  name: 'peeringDeployment'
  params: {
    vnetName: vnet.outputs.vnetName
    vnetResourceGroup: resourceGroup().name
    peerVnetId: '/subscriptions/2323178e-8454-42b7-b2ec-fc8857af816e/resourceGroups/rg-shared-services/providers/Microsoft.Network/virtualNetworks/hub-vnet'
  }
}

module storage '../../modules/storage/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: 'companyastorage'
  }
}

module hostpool '../../modules/avd/hostpool.bicep' = {
  name: 'hostpoolDeployment'
  params: {
    location: location
    adminUsername: adminUsername
    maxSessionHosts: maxSessionHosts
    subnetId: vnet.outputs.subnetId
    dnsServers: [
      '10.0.10.5'
      '10.0.10.4'
    ]
    storageAccountId: storage.outputs.storageAccountId
    keyVaultResourceId: keyVaultResourceId
    adminPasswordSecretName: adminPasswordSecretName
    domainName: '' // Add if needed
  }
}

module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}
