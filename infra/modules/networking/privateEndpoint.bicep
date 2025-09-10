@description('Name of the Private Endpoint')
param privateEndpointName string

@description('Azure region')
param location string

@description('Resource ID of the resource to which the Private Endpoint will connect')
param targetResourceId string

@description('Name of the subnet for the Private Endpoint')
param subnetId string

@description('Array of Private DNS Zone Group configs (zone names, resource IDs)')
param privateDnsZoneConfigs array = []

// Example for privateDnsZoneConfigs:
// [
//   {
//     zoneName: 'privatelink.file.core.windows.net'
//     zoneId: '/subscriptions/xxxx/resourceGroups/xxxx/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net'
//   }
// ]

resource pe 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-pls'
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: [] // Specify groupId if needed (e.g., 'file' for Azure Files, 'blob' for Blob)
        }
      }
    ]
    customDnsConfigs: []
  }
}

resource dnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = [for zoneConfig in privateDnsZoneConfigs: {
  name: '${privateEndpointName}-${zoneConfig.zoneName}-zonegroup'
  parent: pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${zoneConfig.zoneName}-config'
        properties: {
          privateDnsZoneId: zoneConfig.zoneId
        }
      }
    ]
  }
}]

output privateEndpointId string = pe.id
output privateEndpointIp string = pe.properties.networkInterfaces[0].properties.ipConfigurations[0].properties.privateIPAddress
