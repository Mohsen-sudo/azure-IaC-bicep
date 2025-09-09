resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: 'companyA-avd-image-fslogix'
  location: resourceGroup().location
  properties: {
    buildTimeoutInMinutes: 80
    vmProfile: {
      vmSize: 'Standard_D2s_v3'
      osDiskSizeGB: 128
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'windows-10'
      sku: 'win10-22h2-ent'
      version: 'latest'
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'InstallFSLogix'
        scriptUri: 'https://raw.githubusercontent.com/Mohsen-sudo/azure-IaC-bicep/main/scripts/fslogix-install.ps1'
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        imageId: '/subscriptions/<sub-id>/resourceGroups/<gallery-rg>/providers/Microsoft.Compute/galleries/<gallery-name>/images/<image-name>'
        location: [resourceGroup().location]
        runOutputName: 'companyA-avd-image-fslogix-output'
      }
    ]
  }
}
