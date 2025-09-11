@description('Admin username for session host VM')
param adminUsername string

@description('Admin password for session host VM')
@secure()
param adminPassword string

@description('AVD registration token for host pool')
@secure()
param registrationToken string

@description('Location for resources')
param location string = 'northeurope'

@description('Subnet resource ID for VM')
param subnetId string

resource sessionHostNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'companyA-sessionhost-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource sessionHostVm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'companyA-sessionhost-01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: 'companyA-sessionhost-01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
      }
      customData: base64('') // optional, for more customization
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-10'
        sku: 'win10-21h2-avd'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Standard_LRS' }
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: sessionHostNic.id }
      ]
    }
  }
}

resource avdAgentInstall 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: '${sessionHostVm.name}/AVDAgentInstall'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/installsessionhostagent.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File installsessonhostagent.ps1 -RegistrationToken "${registrationToken}"'
    }
  }
}
