param adminUsername string
@secure()
param adminPassword string
param location string
param vnetAddressPrefixes array
param subnetAddressPrefix string
param maxSessionHosts int
param timestamp string = utcNow() // valid default usage

module vnet '../../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnetAddressPrefix: subnetAddressPrefix
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
  }
}

module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}
