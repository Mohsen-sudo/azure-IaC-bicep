@description('Name of the Private DNS Zone, e.g., privatelink.file.core.windows.net')
param dnsZoneName string

@description('Resource group for the DNS Zone')
param resourceGroupName string

@description('Azure location')
param location string

@description('Array of VNet resource IDs to link to this DNS zone')
param vnetIds array

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: location
}

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for vnetId in vnetIds: {
  name: '${dnsZoneName}-link-${uniqueString(vnetId)}'
  parent: privateDnsZone
  location: location
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}]

output dnsZoneId string = privateDnsZone.id
