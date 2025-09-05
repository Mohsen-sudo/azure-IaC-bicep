param adminUsername string
@secure()
param adminPassword string
param location string
param vnetAddressPrefixes array = ['10.1.0.0/16']
param subnetAddressPrefix string = '10.1.1.0/24'
param maxSessionHosts int = 2
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
    timestamp: timestamp
  }
}

module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}
