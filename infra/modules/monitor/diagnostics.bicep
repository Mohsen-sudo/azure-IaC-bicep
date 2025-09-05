@description('Log Analytics Workspace name')
param workspaceName string

@description('Location')
param location string = resourceGroup().location

resource law 'Microsoft.OperationalInsights/workspaces@2023-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output workspaceId string = law.id
