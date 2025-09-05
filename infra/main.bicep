// Root orchestrator for Hub-Spoke AVD lab

targetScope = 'tenant'

// ========== Parameters ==========
@description('Deployment location for all resources')
param location string = 'northeurope'

@secure()
param adminPassword string

param adminUsername string = 'AVDadmin'
param maxSessionHosts int = 2

// ========== Subscriptions ==========
@description('Hub subscription Id')
param hubSubId string = '2323178e-8454-42b7-b2ec-fc8857af816e' // Azure sub1

@description('Company A subscription Id')
param spokeASubId string = 'bc590447-877b-4cb2-9253-6d4aab175a22' // Azure Sub-A

@description('Company B subscription Id')
param spokeBSubId string = 'ed5e066d-0ce1-4bfa-b62d-edba1e6eb807' // Azure Sub-B

// ========== Hub Deployment ==========
module hub './stacks/shared-services/main.bicep' = {
  name: 'hubDeployment'
  scope: subscription(hubSubId)
  params: {
    location: location
  }
}

// ========== Spoke A ==========
module spokeA './stacks/company-a/main.bicep' = {
  name: 'spokeADeployment'
  scope: subscription(spokeASubId)
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetAddressPrefixes: [
      '10.0.0.0/16'
    ]
    subnetAddressPrefix: '10.0.1.0/24'
    maxSessionHosts: maxSessionHosts
  }
}

// ========== Spoke B ==========
module spokeB './stacks/company-b/main.bicep' = {
  name: 'spokeBDeployment'
  scope: subscription(spokeBSubId)
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetAddressPrefixes: [
      '10.1.0.0/16'
    ]
    subnetAddressPrefix: '10.1.1.0/24'
    maxSessionHosts: maxSessionHosts
  }
}
