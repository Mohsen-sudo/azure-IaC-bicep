@description('Name of the route table')
param routeTableName string

@description('Azure region for the route table')
param location string

@description('Optional: Array of custom routes for this route table')
param customRoutes array = []

resource routeTable 'Microsoft.Network/routeTables@2021-05-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: customRoutes
  }
}

output routeTableId string = routeTable.id
