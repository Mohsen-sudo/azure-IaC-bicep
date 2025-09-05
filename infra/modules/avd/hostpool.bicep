param location string
param adminUsername string
@secure()
param adminPassword string
param maxSessionHosts int
param subnetId string
param timestamp string = utcNow() // valid default usage

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-09-01-privatepreview' = {
  name: 'hostpool-companyA'
  location: location
  properties: {
    friendlyName: 'CompanyA Hostpool'
    description: 'AVD Hostpool'
    hostPoolType: 'Pooled'
    maxSessionLimit: 16
    loadBalancerType: 'BreadthFirst'
    personalDesktopAssignmentType: 'Automatic'
    customRdpProperty: ''
  }
}

output hostPoolId string = hostPool.id
