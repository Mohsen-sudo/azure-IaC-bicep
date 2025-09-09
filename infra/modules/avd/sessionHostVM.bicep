param vmName string
param location string

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vmName
  location: location
  properties: {
    // ... your VM properties ...
  }
}

resource fslogixInstall 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: '${vm.name}/FSLogixInstall'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        // 1. The PowerShell script to execute
        'https://companyastorage.blob.core.windows.net/fxlogixsetup/Install-FSLogix.ps1?sp=r&st=2025-09-08T17:53:16Z&se=2025-09-09T02:08:16Z&spr=https&sv=2024-11-04&sr=b&sig=u2Wh8UweSswDfS0cs703jXjvbYqPhWGZUhl1dn5b9Ds%3D'
        // 2. FSLogix Apps installer
        'https://companyastorage.blob.core.windows.net/fxlogixsetup/FSLogixAppsSetup.exe?sp=r&st=2025-09-08T17:52:53Z&se=2025-09-09T02:07:53Z&spr=https&sv=2024-11-04&sr=b&sig=%2BYV6TKyvJNnZBdzRLLq1ldgyUBkfOdV4Ma3MOt%2BXt8o%3D'
        // 3. FSLogix Rule Editor installer
        'https://companyastorage.blob.core.windows.net/fxlogixsetup/FSLogixAppsRuleEditorSetup.exe?sp=r&st=2025-09-08T17:50:24Z&se=2025-09-09T02:05:24Z&spr=https&sv=2024-11-04&sr=b&sig=MNyvK5ZNLO6AOBz%2FJYXFx4GqLhNUoy1det%2B5UxZsF%2BE%3D'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Install-FSLogix.ps1'
    }
  }
  dependsOn: [
    vm
  ]
}
