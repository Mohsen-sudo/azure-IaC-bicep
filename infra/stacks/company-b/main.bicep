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
  }
}

module nsg '../../modules/networking/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    nsgName: 'companyB-nsg'
    customRules: []
  }
}

module peering '../../modules/networking/peering.bicep' = {
  name: 'peeringDeployment'
  params: {
    vnetName: vnet.outputs.vnetName // Ensure vnet.bicep outputs this
    vnetResourceGroup: 'rg-company-b' // Replace with actual resource group
    peerVnetId: '<hubVnet resource id>' // Replace with actual resource id
  }
}

module storage '../../modules/storage/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: 'companybstorage' // Replace if needed
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
      '10.0.20.5'
      '10.0.20.4'
    ]
    storageAccountId: storage.outputs.storageAccountId
    // Add additional params if needed
  }
}

module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}
