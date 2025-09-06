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
    subnetId: vnet.outputs.subnetId
    // Add security rule parameters as needed
  }
}

module peering '../../modules/networking/peering.bicep' = {
  name: 'peeringDeployment'
  params: {
    location: location
    vnetId: vnet.outputs.vnetId
    peerVnetId: '<hubVnet resource id>'
  }
}

module storage '../../modules/storage/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    // Add storage parameters as needed
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
    // Add additional params for domain join (domain, OU, etc)
  }
}

module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}
