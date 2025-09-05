param location string
param hostPoolId string

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2025-05-30-preview' = {
  name: 'workspace-companyA'
  location: location
  properties: {
    description: 'Company A AVD Workspace'
    friendlyName: 'Company A Workspace'
    hostPoolIds: [
      hostPoolId
    ]
  }
}

output workspaceId string = workspace.id
