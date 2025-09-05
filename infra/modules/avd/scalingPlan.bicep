@description('Name of Scaling Plan')
param scalingPlanName string
@description('Location')
param location string
@description('Host Pool ID')
param hostPoolId string

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2024-09-01-preview' = {
  name: scalingPlanName
  location: location
  properties: {
    description: 'Scaling plan for AVD host pool'
    hostPoolReferences: [
      hostPoolId
    ]
    peakSchedules: []
  }
}

output scalingPlanId string = scalingPlan.id
