@description('AVD Host Pool registration token')
@secure()
param registrationToken string

@description('Domain FQDN')
param domainName string

@description('Domain Join Username')
param domainJoinUsername string

@description('Domain Join Password')
@secure()
param domainJoinPassword string

resource domainJoin 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: '${avdVm.name}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      "Name": domainName
      "OUPath": ""
      "User": domainJoinUsername
      "Restart": "true"
      "Options": "3"
    }
    protectedSettings: {
      "Password": domainJoinPassword
    }
  }
}

resource avdAgent 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: '${avdVm.name}/avdagent'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      "commandToExecute": 'powershell -ExecutionPolicy Unrestricted -File register-avd.ps1'
    }
    protectedSettings: {
      "script": '''
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $token="${registrationToken}"
        $url="https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE2JwUy"
        $agentInstaller="C:\\avdagent.msi"
        Invoke-WebRequest -Uri $url -OutFile $agentInstaller
        Start-Process msiexec.exe -ArgumentList '/i', $agentInstaller, '/quiet', '/qn', "REGISTRATIONTOKEN=$token" -Wait
        Remove-Item $agentInstaller
      '''
    }
  }
}
