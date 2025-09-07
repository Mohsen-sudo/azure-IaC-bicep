param adminUsername string
@secure()
param adminPassword string
param location string
param vnetAddressPrefixes array
param subnetAddressPrefix string
param maxSessionHosts int
param timestamp string = utcNow()

module vnet '../../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnetAddressPrefix: subnetAddressPrefix
    vnetName: 'vnet-companyA' // Only if your vnet.bicep supports vnetName param
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
    vnetResourceGroup: 'rg-company-a' // or: resourceGroup().name
    peerVnetId: '<hubVnet resource id>' // Replace with your actual Hub VNet resource ID
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
    adminPassword: adminPassword
    maxSessionHosts: maxSessionHosts
    subnetId: vnet.outputs.subnetId
    dnsServers: [
      '10.0.10.5'
      '10.0.10.4'
    ]
    storageAccountId: storage.outputs.storageAccountId
    // Add domain join params if required (domain, OU, etc)
  }
}

module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}
