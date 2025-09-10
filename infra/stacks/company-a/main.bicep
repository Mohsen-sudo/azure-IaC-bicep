@description('Username for admin access to session hosts')
param adminUsername string

@secure()
@description('Admin password, securely referenced from Key Vault in your parameter file')
param adminPassword string

@description('Azure location for all resources')
param location string

@description('Virtual Network address prefix for Company A. MUST NOT overlap with hubVnet (e.g., use 10.1.0.0/16)')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Address prefix for single subnet (used by DC and AVD hosts)')
param subnetAddressPrefix string = '10.1.1.0/24'

@description('Maximum number of AVD session hosts in pool 01')
param maxSessionHostsPool01 int

@description('Maximum number of AVD session hosts in pool 02')
param maxSessionHostsPool02 int

@description('Short prefix for AVD session hosts computer name (max 7 chars recommended)')
param sessionHostPrefix string = 'cmpA-avd'

@description('Name of the NAT Gateway resource for Company A')
param natGatewayName string = 'companyA-natgw'

@description('Name of the Public IP for NAT Gateway')
param publicIpName string = 'companyA-natgw-pip'

@description('Optional: Deploy a custom route table and associate to subnet')
param deployRouteTable bool = false

@description('Custom routes for the route table (if used)')
param customRoutes array = []

@description('Deploy FSLogix Private Endpoint and DNS config for Azure Files')
param deployFslogixPrivateEndpoint bool = true

@description('Private DNS Zone resource ID for privatelink.file.core.windows.net')
param privateDnsZoneId string = ''

@description('Hub VNet resource ID for peering')
param hubVnetId string

// AADDS DNS IPs (update if your AADDS IPs change!)
var aaddsDnsIps = [
  '10.0.10.4'
  '10.0.10.5'
]

// VNet with one subnet
module vnet '../../modules/networking/vnet-single-subnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    addressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
    vnetName: 'vnet-companyA'
    natGatewayName: natGatewayName
    publicIpName: publicIpName
    dnsServers: aaddsDnsIps
    routeTableName: deployRouteTable ? 'companyA-rt' : ''
    customRoutes: customRoutes
  }
}

// NSG for Company A
module nsg '../../modules/networking/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    nsgName: 'companyA-nsg'
    subnetIds: [
      vnet.outputs.subnetId
    ]
    customRules: []
  }
}

// VNet Peering to shared hubVnet
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: 'peer-to-hub'
  parent: vnet.outputs.vnetName
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
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

// Domain Controller VM (in subnet)
module dcVm '../../modules/domainController.bicep' = {
  name: 'companyA-dc'
  params: {
    location: location
    subnetId: vnet.outputs.subnetId
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: 'CompanyA.local'
    dnsServers: aaddsDnsIps
  }
}

// First AVD host pool in subnet
module avdHostpool01 '../../modules/avd/hostpool.bicep' = {
  name: 'companyA-avd-hostpool-01'
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    maxSessionHosts: maxSessionHostsPool01
    subnetId: vnet.outputs.subnetId
    dnsServers: aaddsDnsIps
    storageAccountId: storage.outputs.storageAccountId
    domainName: 'CompanyA.local'
    sessionHostPrefix: '${sessionHostPrefix}-01'
    // Add FSLogix profile path if required as a parameter in your hostpool module
  }
}

// Second AVD host pool in subnet
module avdHostpool02 '../../modules/avd/hostpool.bicep' = {
  name: 'companyA-avd-hostpool-02'
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    maxSessionHosts: maxSessionHostsPool02
    subnetId: vnet.outputs.subnetId
    dnsServers: aaddsDnsIps
    storageAccountId: storage.outputs.storageAccountId
    domainName: 'CompanyA.local'
    sessionHostPrefix: '${sessionHostPrefix}-02'
    // Add FSLogix profile path if required as a parameter in your hostpool module
  }
}

// Workspace for Company A (optional, can be deployed per pool)
module workspace01 '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment01'
  params: {
    location: location
    hostPoolId: avdHostpool01.outputs.hostPoolId
  }
}

module workspace02 '../../modules/avd/workspace.bicep' = {
  name: 'workspaceDeployment02'
  params: {
    location: location
    hostPoolId: avdHostpool02.outputs.hostPoolId
  }
}
