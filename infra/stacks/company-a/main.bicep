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

@description('Optional: Deploy a custom route table and associate to AVD subnet')
param deployRouteTable bool = false

@description('Custom routes for the route table (if used)')
param customRoutes array = []

@description('Deploy FSLogix Private Endpoint and DNS config for Azure Files')
param deployFslogixPrivateEndpoint bool = true

@description('Private DNS Zone resource ID for privatelink.file.core.windows.net')
param privateDnsZoneId string = ''

// AADDS DNS IPs (update if your AADDS IPs change!)
var aaddsDnsIps = [
  '10.0.10.4'
  '10.0.10.5'
]

// NAT Gateway for outbound internet on AVD subnet
module natGateway '../../modules/avd/nat-gateway-avd.bicep' = {
  name: 'natGatewayDeployment'
  params: {
    location: location
    natGatewayName: natGatewayName
    publicIpName: publicIpName
  }
}

// Optional Route Table deployment
module routeTable '../../modules/networking/routeTable.bicep' = if (deployRouteTable) {
  name: 'routeTableDeployment'
  params: {
    location: location
    routeTableName: 'companyA-rt'
    customRoutes: customRoutes
  }
}

// Company A VNet, attach NAT Gateway, set DNS to use AADDS, associate route table if enabled
module vnet '../../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnetAddressPrefix: subnetAddressPrefix
    vnetName: 'vnet-companyA'
    natGatewayId: natGateway.outputs.natGatewayId
    dnsServers: aaddsDnsIps
    routeTableId: deployRouteTable ? routeTable.outputs.routeTableId : null
  }
}

// NSG for Company A (ensure the referenced nsg.bicep contains robust AVD/AADDS rules)
module nsg '../../modules/networking/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    nsgName: 'companyA-nsg'
    customRules: []
  }
}

// VNet Peering to shared hubVnet
module peering '../../modules/networking/peering.bicep' = {
  name: 'peeringDeployment'
  params: {
    vnetName: vnet.outputs.vnetName
    peerVnetId: '/subscriptions/2323178e-8454-42b7-b2ec-fc8857af816e/resourceGroups/rg-shared-services/providers/Microsoft.Network/virtualNetworks/hubVnet'
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

// Storage for Company A (used for FSLogix profiles)
module storage '../../modules/storage/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: 'companyastorage'
  }
}

// FSLogix Private Endpoint for Azure Files (+ Private DNS Zone group link)
module fslogixPrivateEndpoint '../../modules/networking/privateEndpoint.bicep' = if (deployFslogixPrivateEndpoint) {
  name: 'fslogixPrivateEndpointDeployment'
  params: {
    privateEndpointName: 'companyA-fslogix-pe'
    location: location
    targetResourceId: storage.outputs.storageAccountId
    subnetId: vnet.outputs.subnetId
    privateDnsZoneConfigs: [
      {
        zoneName: 'privatelink.file.core.windows.net'
        zoneId: privateDnsZoneId
      }
    ]
    // For Azure Files, set groupIds to ['file'] in privateEndpoint.bicep if required
  }
}

// Hostpool (AVD) deployment, with domain join, DNS, and FSLogix config
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
    // Add FSLogix profile path if required as a parameter in your hostpool module
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
