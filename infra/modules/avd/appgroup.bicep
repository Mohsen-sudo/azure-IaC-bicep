param location string
param hostPoolId string
param appGroupName string

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-09-01-preview' = {
  name: appGroupName
  location: location
  properties: {
    hostPoolId: hostPoolId
    description: 'AVD App Group for Company A'
    type: 'RemoteApp'
  }
}

output appGroupId string = appGroup.id
