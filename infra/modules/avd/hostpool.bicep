@description('Location for all resources')
param location string

@description('Admin username for session hosts')
param adminUsername string

@secure()
@description('Admin password for session hosts')
param adminPassword string

@description('Company prefix for naming resources')
param companyPrefix string = 'companyA'

@minValue(1)
@maxValue(5) // 5 hosts max, each Standard_D2s_v3 (2 vCPU), max 10 vCPUs
@description('Number of session hosts to deploy. With Standard_D2s_v3, do not set above 5 for a 10 vCPU quota.')
param maxSessionHosts int = 2

@description('Subnet ID where session hosts will be deployed')
param subnetId string

@description('DNS servers (AD DS IPs) for the VMs')
param dnsServers array = []

@description('Domain name for joining the session hosts')
param domainName string = 'corp.mohsenlab.local'

@allowed([
  'Standard_D2s_v3'
  'Standard_B2ms'
])
@description('VM size for session hosts. Default is Standard_D2s_v3 (2 vCPU).')
param vmSize string = 'Standard_D2s_v3'

@description('Windows image for session hosts')
param vmImagePublisher string = 'MicrosoftWindowsDesktop'
param vmImageOffer string = 'windows-10'
param vmImageSku string = 'win10-21h2-avd'
param vmImageVersion string = 'latest'

@description('Storage account ID for FSLogix profile container')
param storageAccountId string

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-09-01-privatepreview' = {
  name: '${companyPrefix}-hostpool'
  location: location
  properties: {
    friendlyName: '${companyPrefix} Hostpool'
    description: 'AVD Hostpool for ${companyPrefix}'
    hostPoolType: 'Pooled'
    maxSessionLimit: maxSessionHosts
    loadBalancerType: 'BreadthFirst'
    personalDesktopAssignmentType: 'Automatic'
    customRdpProperty: ''
  }
}

resource sessionHostNICs 'Microsoft.Network/networkInterfaces@2023-05-01' = [for i in range(0, maxSessionHosts): {
  name: '${companyPrefix}-avd-nic-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    dnsSettings: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
  }
}]

resource sessionHostVMs 'Microsoft.Compute/virtualMachines@2023-03-01' = [for i in range(0, maxSessionHosts): {
  name: '${companyPrefix}-avd-host-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${companyPrefix}-avd-host-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
      customData: base64('''
      $secPassword = ConvertTo-SecureString '${adminPassword}' -AsPlainText -Force
      $cred = New-Object System.Management.Automation.PSCredential('${adminUsername}', $secPassword)
      Add-Computer -DomainName ${domainName} -Credential $cred -Restart
      ''')
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
        version: vmImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: sessionHostNICs[i].id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  dependsOn: [
    sessionHostNICs
    hostPool
  ]
}]

resource fslogixExtensions 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, maxSessionHosts): {
  name: '${sessionHostVMs[i].name}/FSLogixProfile'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/MicrosoftDocs/fslogix-docs/master/scripts/Install-FSLogix.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Install-FSLogix.ps1 -StorageAccountId ${storageAccountId}'
    }
  }
  dependsOn: [
    sessionHostVMs
  ]
}]

output hostPoolId string = hostPool.id
output sessionHostVMNames array = [for i in range(0, maxSessionHosts): '${companyPrefix}-avd-host-${i}']
output sessionHostNICNames array = [for i in range(0, maxSessionHosts): '${companyPrefix}-avd-nic-${i}']
