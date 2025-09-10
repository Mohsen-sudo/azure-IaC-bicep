@description('Location for resources')
param location string

@description('Admin username for the domain controller VMs')
param addsVmAdminUsername string

@description('Admin password for the domain controller VMs')
@secure()
param adminPassword string

@description('ADDSSubnetA resource ID (must be full Azure subnet resourceId, e.g. /subscriptions/xxxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx/subnets/xxx)')
param addsSubnetAId string

@description('ADDSSubnetB resource ID (must be full Azure subnet resourceId, e.g. /subscriptions/xxxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx/subnets/xxx)')
param addsSubnetBId string

var vmSize = 'Standard_B1s'
var imageRef = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-Datacenter'
  version: 'latest'
}

// Validation: ensure subnet IDs are not empty, fail with helpful error if so
var addsSubnetAIdIsValid = !empty(addsSubnetAId) && startsWith(addsSubnetAId, '/subscriptions/')
var addsSubnetBIdIsValid = !empty(addsSubnetBId) && startsWith(addsSubnetBId, '/subscriptions/')

module failIfSubnetAIdInvalid 'br/public/validation:fail/1.0.1' = if (!addsSubnetAIdIsValid) {
  name: 'failIfSubnetAIdInvalid'
  params: {
    errorMessage: 'Parameter addsSubnetAId is empty or not a valid Azure resourceId. Please pass the full subnet resource ID.'
  }
}
module failIfSubnetBIdInvalid 'br/public/validation:fail/1.0.1' = if (!addsSubnetBIdIsValid) {
  name: 'failIfSubnetBIdInvalid'
  params: {
    errorMessage: 'Parameter addsSubnetBId is empty or not a valid Azure resourceId. Please pass the full subnet resource ID.'
  }
}

// CompanyA Domain Controller VM NIC
resource addsVmA_nic 'Microsoft.Network/networkInterfaces@2023-09-01' = if (addsSubnetAIdIsValid) {
  name: 'adds-dcA-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: addsSubnetAId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// CompanyA Domain Controller VM
resource addsVmA 'Microsoft.Compute/virtualMachines@2023-07-01' = if (addsSubnetAIdIsValid) {
  name: 'adds-dcA'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'adds-dcA'
      adminUsername: addsVmAdminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imageRef
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: addsVmA_nic.id
        }
      ]
    }
  }
}

// CompanyB Domain Controller VM NIC
resource addsVmB_nic 'Microsoft.Network/networkInterfaces@2023-09-01' = if (addsSubnetBIdIsValid) {
  name: 'adds-dcB-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: addsSubnetBId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// CompanyB Domain Controller VM
resource addsVmB 'Microsoft.Compute/virtualMachines@2023-07-01' = if (addsSubnetBIdIsValid) {
  name: 'adds-dcB'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'adds-dcB'
      adminUsername: addsVmAdminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imageRef
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: addsVmB_nic.id
        }
      ]
    }
  }
}

output addsVmA_id string = addsVmA.id
output addsVmB_id string = addsVmB.id
