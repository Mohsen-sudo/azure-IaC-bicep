param location string
param adminUsername string
@secure()
param adminPassword string
param maxSessionHosts int
param subnetId string
param domainName string
param domainJoinUser string
@secure()
param domainJoinPassword string
param storageAccountId string // For FSLogix profile container
param vmSize string = 'Standard_D2s_v3'
param vmImagePublisher string = 'MicrosoftWindowsDesktop'
param vmImageOffer string = 'windows-10'
param vmImageSku string = 'win10-21h2-avd'
param vmImageVersion string = 'latest'
param companyPrefix string = 'companyA'
param dnsServers array = []
param timestamp string = utcNow()

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

// Create NICs for session hosts
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
    // Optional: set DNS servers if provided
    dnsSettings: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
  }
}]

// Create session host VMs
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
      secrets: []
      customData: base64(concat(
        "#ps1_sysnative\n",
        "Add-Computer -DomainName ", domainName,
        " -Credential (New-Object System.Management.Automation.PSCredential('", domainJoinUser, "',(ConvertTo-SecureString '", domainJoinPassword, "' -AsPlainText -Force)))",
        "\nRestart-Computer -Force"
      ))
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
    extensionProfile: {
      extensions: [
        {
          name: 'FSLogixProfile'
          properties: {
            publisher: 'Microsoft.Compute'
            type: 'CustomScriptExtension'
            typeHandlerVersion: '1.10'
            autoUpgradeMinorVersion: true
            settings: {
              fileUris: [
                // Reference your FSLogix install script here (public or private)
                'https://raw.githubusercontent.com/MicrosoftDocs/fslogix-docs/master/scripts/Install-FSLogix.ps1'
              ]
              commandToExecute: concat('powershell -ExecutionPolicy Unrestricted -File Install-FSLogix.ps1 -StorageAccountId ', storageAccountId)
            }
          }
        }
      ]
    }
  }
  dependsOn: [
    sessionHostNICs
    hostPool
  ]
}]

output hostPoolId string = hostPool.id
output sessionHostVMNames array = [for i in range(0, maxSessionHosts): '${companyPrefix}-avd-host-${i}']
output sessionHostNICNames array = [for i in range(0, maxSessionHosts): '${companyPrefix}-avd-nic-${i}']
