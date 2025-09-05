@description('Location')
param location string
@description('Session Host VM name')
param vmName string
@description('Host pool ID')
param hostPoolId string

resource sessionHost 'Microsoft.DesktopVirtualization/sessionHosts@2021-07-12' = {
  name: vmName
  location: location
  properties: {
    hostPoolArmPath: hostPoolId
    friendlyName: vmName
    sessionHostType: 'Personal'
  }
}

output sessionHostId string = sessionHost.id
