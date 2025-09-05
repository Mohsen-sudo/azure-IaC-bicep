@description('Location for all resources')
param location string

// Networking - VNet
module vnetModule '../../modules/networking/vnet.bicep' = {
  name: 'vnetModule'
  params: {
    location: location
  }
}

// Networking - VPN Gateway
module vpnGatewayModule '../../modules/networking/vpnGateway.bicep' = {
  name: 'vpnGatewayModule'
  params: {
    location: location
    vnetId: vnetModule.outputs.vnetId
    vpnPIPName: 'sharedServicesVPNPIP'
  }
}

// Identity - Key Vault
module kvModule '../../modules/identity/keyVault.bicep' = {
  name: 'kvModule'
  params: {
    location: location
    vaultName: 'sharedServicesKV25MOHSEN'
  }
}

// Monitoring - Log Analytics
module lawModule '../../modules/monitor/logAnalytics.bicep' = {
  name: 'lawModule'
  params: {
    location: location
    workspaceName: 'sharedServicesLAW'
  }
}

// Outputs
output vnetId string = vnetModule.outputs.vnetId
output vpnGatewayId string = vpnGatewayModule.outputs.vpnGatewayId
output keyVaultId string = kvModule.outputs.keyVaultId
output lawId string = lawModule.outputs.workspaceId
