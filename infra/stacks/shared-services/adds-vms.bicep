@description('Location for resources')
param location string

@description('Admin username for the domain controller VMs')
param addsVmAdminUsername string

@description('Admin password for the domain controller VMs')
@secure()
param adminPassword string

@description('ADDSSubnetA resource ID')
param addsSubnetAId string

@description('ADDSSubnetB resource ID')
param addsSubnetBId string

var vmSize = 'Standard_DS2_v2'
var imageRef = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-Datacenter'
  version: 'latest'
}

// CompanyA Domain Controller VM
resource addsVmA_nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
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

resource addsVmA 'Microsoft.Compute/virtualMachines@2023-07-01' = {
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

// CompanyB Domain Controller VM
resource addsVmB_nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
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

resource addsVmB 'Microsoft.Compute/virtualMachines@2023-07-01' = {
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
