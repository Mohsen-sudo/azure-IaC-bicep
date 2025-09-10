@description('Username for admin access to session hosts')
param adminUsername string

@secure()
@description('Admin password, securely referenced from Key Vault in your parameter file')
param adminPassword string

@description('Azure location for all resources')
param location string

@description('Virtual Network address prefixes for Company A')
param vnetAddressPrefixes array

@description('Subnet address prefix for Company A')
param subnetAddressPrefix string

@description('Maximum number of AVD session hosts')
param maxSessionHosts int

@description('Short prefix for AVD session hosts computer name (max 7 chars recommended)')
param sessionHostPrefix string = 'cmpA-avd'

@description('Name of the NAT Gateway resource for Company A')
param natGatewayName string = 'companyA-natgw'

@description('Name of the Public IP for NAT Gateway')
param publicIpName string = 'companyA-natgw-pip'

// AADDS DNS IPs - update these if your AADDS IPs change!
var aaddsDnsIps = [
  '10.0.10.4'
  '10.0.10.5'
]

// NAT Gateway for outbound internet on AVD subnet (deploy first)
module natGateway '../../modules/avd/nat-gateway-avd.bicep' = {
  name: 'natGatewayDeployment'
  params: {
    location: location
    natGatewayName: natGatewayName
    publicIpName: publicIpName
  }
}

// Deploy Company A VNet, attach NAT Gateway to subnet, set DNS to use AADDS
module vnet '../../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnetAddressPrefix: subnetAddressPrefix
    vnetName: 'vnet-companyA'
    natGatewayId: natGateway.outputs.natGatewayId
    // Only AADDS DNS for domain join
    dnsServers: aaddsDnsIps
  }
}

// Deploy NSG for Company A, with secure and complete rules
module nsg '../../modules/networking/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    nsgName: 'companyA-nsg'
    // No custom rules for now, but could add jumpbox/public IP for RDP if needed
    customRules: []
  }
}

// VNet Peering to shared hubVnet
module peering '../../modules/networking/peering.bicep' = {
  name: 'peeringDeployment'
  params: {
    vnetName: vnet.outputs.vnetName
    peerVnetId: '/subscriptions/2323178e-8454-42b7-b2ec-fc8857af816e/resourceGroups/rg-shared-services/providers/Microsoft.Network/virtualNetworks/hubVnet'
    allowForwardedTraffic: true // Best practice for AVD/hub scenarios
    allowGatewayTransit: false
  }
}

// Storage for Company A
module storage '../../modules/storage/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: 'companyastorage'
  }
}

// Hostpool (AVD) deployment, with domain join and AAD DS DNS settings
module hostpool '../../modules/avd/hostpool.bicep' = {
  name: 'hostpoolDeployment'
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    maxSessionHosts: maxSessionHosts
    subnetId: vnet.outputs.subnetId
    dnsServers: aaddsDnsIps
    storageAccountId: storage.outputs.storageAccountId
    domainName: 'corp.mohsenlab.local'
    sessionHostPrefix: sessionHostPrefix
  }
}

// Workspace for Company A
module workspace '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment'
  params: {
    location: location
    hostPoolId: hostpool.outputs.hostPoolId
  }
}
