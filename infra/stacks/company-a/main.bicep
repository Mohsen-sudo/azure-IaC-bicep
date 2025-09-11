trigger:
  branches:
    include:
      - main

variables:
  hubSubscription: "Azure sub1"
  spoke1Subscription: "Azure Sub-A"
  spoke2Subscription: "Azure Sub-B"
  location: "northeurope"
  keyVaultName: "sharedServicesKV-Mohsen"
  wifServiceConnection: "WIF-HubSpokes-Root"
  AZURE_SERVICE_CONNECTION: "WIF-HubSpokes-Root"
  domainName: "contoso.local"
  domainSecurityGroup: "AADDSAdmins"

stages:
# ----------------------------------------------------------------------
# Stage 1 - Deploy Hub
# ----------------------------------------------------------------------
- stage: SharedServices
  displayName: 'Deploy Shared Services (Hub)'
  jobs:
    - job: DeploySharedServices
      displayName: 'Deploy Hub Resources'
      pool:
        name: 'IaC-agent-pool'
      steps:
        - task: AzureCLI@2
          displayName: 'Deploy Shared Services Bicep'
          inputs:
            azureSubscription: '$(wifServiceConnection)'
            scriptType: 'pscore'
            scriptLocation: 'inlineScript'
            inlineScript: |
              az account set --subscription "$(hubSubscription)"
              az group create --name rg-shared-services --location $(location)
              az deployment group create --resource-group rg-shared-services `
                --template-file infra/stacks/shared-services/main.bicep `
                --parameters "@infra/stacks/shared-services/main.json" `
                --only-show-errors --output none

# ----------------------------------------------------------------------
# Stage 2 - Manual Approval
# ----------------------------------------------------------------------
- stage: ManualApproval
  displayName: 'Manual Approval Before Spokes'
  dependsOn: SharedServices
  jobs:
    - job: WaitForApproval
      displayName: 'Wait for Manual Approval'
      pool: server
      steps:
        - task: ManualValidation@0
          inputs:
            notifyUsers: 'boxclean@gmail.com'
            instructions: 'Please review the Shared Services deployment before proceeding to Spoke deployments.'
            timeout: '0'

# ----------------------------------------------------------------------
# Stage 3 - Deploy Company A (Spoke 1)
# ----------------------------------------------------------------------
- stage: CompanyA
  displayName: 'Deploy Company A (Spoke 1)'
  dependsOn: ManualApproval
  jobs:
    - job: DeployCompanyA
      displayName: 'Deploy Company A Resources'
      pool:
        name: 'IaC-agent-pool'
      steps:
        # Fetch secrets from Hub Key Vault
        - task: AzureKeyVault@2
          displayName: Fetch Company A secrets from Key Vault
          inputs:
            azureSubscription: '$(wifServiceConnection)'
            scriptType: pscore
            scriptLocation: inlineScript
            inlineScript: |
              echo "Fetching Company A secrets..."
              $username = az keyvault secret show --vault-name "$(keyVaultName)" --name "CompanyAAdminUsername" --query value -o tsv
              $password = az keyvault secret show --vault-name "$(keyVaultName)" --name "CompanyAAdminPassword" --query value -o tsv

              echo "##vso[task.setvariable variable=CompanyAAdminUsername;issecret=true]$username"
              echo "##vso[task.setvariable variable=CompanyAAdminPassword;issecret=true]$password"

        # Deploy Company A resources
        - task: AzureResourceManagerTemplateDeployment@3
          displayName: 'Deploy Company A Bicep (ARM Task)'
          inputs:
            deploymentScope: 'Resource Group'
            azureResourceManagerConnection: '$(AZURE_SERVICE_CONNECTION)'
            subscriptionId: 'bc590447-877b-4cb2-9253-6d4aab175a22'
            resourceGroupName: 'rg-company-a'
            location: '$(location)'
            templateLocation: 'Linked artifact'
            csmFile: 'infra/stacks/company-a/main.bicep'
            csmParametersFile: 'infra/stacks/company-a/company-a.parameters.json'
            overrideParameters: >
              -adminUsername "$(CompanyAAdminUsername)"
              -adminPassword "$(CompanyAAdminPassword)"
            deploymentMode: 'Incremental'

# ----------------------------------------------------------------------
# Stage 4 - Deploy Company B (Spoke 2)
# ----------------------------------------------------------------------
- stage: CompanyB
  displayName: 'Deploy Company B (Spoke 2)'
  dependsOn: ManualApproval
  jobs:
    - job: DeployCompanyB
      displayName: 'Deploy Company B Resources'
      pool:
        name: 'IaC-agent-pool'
      steps:
        # Fetch secrets from Hub Key Vault
        - task: AzureCLI@2
          displayName: Fetch Company B secrets from Key Vault
          inputs:
            azureSubscription: '$(wifServiceConnection)'
            scriptType: pscore
            scriptLocation: inlineScript
            inlineScript: |
              echo "Fetching Company B secrets..."
              $username = az keyvault secret show --vault-name "$(keyVaultName)" --name "CompanyBAdminUsername" --query value -o tsv
              $password = az keyvault secret show --vault-name "$(keyVaultName)" --name "CompanyBAdminPassword" --query value -o tsv

              echo "##vso[task.setvariable variable=CompanyBAdminUsername;issecret=true]$username"
              echo "##vso[task.setvariable variable=CompanyBAdminPassword;issecret=true]$password"

        # Deploy Company B resources
        - task: AzureCLI@2
          displayName: 'Deploy Company B Bicep'
          inputs:
            azureSubscription: '$(wifServiceConnection)'
            scriptType: 'pscore'
            scriptLocation: 'inlineScript'
            inlineScript: |
              az account set --subscription "$(spoke2Subscription)"
              az group create --name rg-company-b --location $(location)
              az deployment group create --resource-group rg-company-b `
                --template-file infra/stacks/company-b/main.bicep `
                --parameters "@infra/stacks/company-b/company-b.parameters.json" `
                --parameters adminUsername="$(CompanyBAdminUsername)" adminPassword="$(CompanyBAdminPassword)" `
                --only-show-errors --output none
