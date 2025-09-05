@description('Location for Log Analytics Workspace')
param location string

@description('Workspace name')
param workspaceName string

resource law 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Output
output workspaceId string = law.id
