param location string
param adminUsername string
param companyPrefix string = 'companyA'
param maxSessionHosts int
param subnetId string
param domainName string
param storageAccountId string // For FSLogix profile container
param vmSize string = 'Standard_D2s_v3'
param vmImagePublisher string = 'MicrosoftWindowsDesktop'
param vmImageOffer string = 'windows-10'
param vmImageSku string = 'win10-21h2-avd'
param vmImageVersion string = 'latest'
param dnsServers array = []
param timestamp string = utcNow()

// Key Vault values
param keyVaultResourceId string = '/subscriptions/2323178e-8454-42b7-b2ec-fc8857af816e/resourceGroups/rg-shared-services/providers/Microsoft.KeyVault/vaults/sharedServicesKV25momo'
@allowed([
  'CompanyAAdminPassword'
  'CompanyBAdminPassword'
])
param adminPasswordSecretName string = 'CompanyAAdminPassword'

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
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
      secrets: [
        {
          sourceVault: {
            id: keyVaultResourceId
          }
          vaultCertificates: []
          vaultSecrets: [
            {
              secretName: adminPasswordSecretName
            }
          ]
        }
      ]
      customData: base64(concat(
        "#ps1_sysnative\n",
        "Add-Computer -DomainName ", domainName, "\n",
        "Restart-Computer -Force"
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
