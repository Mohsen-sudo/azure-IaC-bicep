// CompanyA ↔ Hub Peering
module companyAToHub 'peering.bicep' = {
  name: 'companyA-to-hub-peering'
  params: {
    localVnetId: vnet.id
    peerVnetId: hubVnetId
    peeringName: 'companyA-to-hub'
  }
}

module hubToCompanyA 'peering.bicep' = {
  name: 'hub-to-companyA-peering'
  scope: resourceGroup(resourceId(hubVnetId).resourceGroup)
  params: {
    localVnetId: hubVnetId
    peerVnetId: vnet.id
    peeringName: 'hub-to-companyA'
  }
}

// CompanyA ↔ ADDS Peering
module companyAToAdds 'peering.bicep' = {
  name: 'companyA-to-adds-peering'
  params: {
    localVnetId: vnet.id
    peerVnetId: addsVnetId
    peeringName: 'companyA-to-adds'
  }
}

module addsToCompanyA 'peering.bicep' = {
  name: 'adds-to-companyA-peering'
  scope: resourceGroup(resourceId(addsVnetId).resourceGroup)
  params: {
    localVnetId: addsVnetId
    peerVnetId: vnet.id
    peeringName: 'adds-to-companyA'
  }
}
