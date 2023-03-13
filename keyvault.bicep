@description('Specifies the Azure location where the resources should be created.')
param location string = resourceGroup().location

@description('The name for the user-assigned managed identity')
param uamiName string

@description('The hostname for the Key Vault')
param keyvaultName string

@description('The name for the Key Vault secret')
param secretName string

@description('The value for the secret to be used by GitHub')
@secure()
param secretValue string 

@description('The GitHub user or organization name')
param githubOrgOrUser string

@description('The GitHub repo name')
param githubRepo string

@description('The GitHub repository\'s branch name')
param githubBranch string = 'main'

param defaultAudience string = 'api://AzureADTokenExchange'

var keyVaultRoleID = {
  'Key Vault Secrets User': '4633458b-17de-408a-b874-0445c86b69e6'
}
var github = {
  issuer: 'https://token.actions.githubusercontent.com'
  subject: 'repo:${githubOrgOrUser}/${githubRepo}:ref:refs/heads/${githubBranch}'
  audience: defaultAudience
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
  resource federatedCred 'federatedIdentityCredentials' = {
    name: 'github'
    properties: {
      issuer: github.issuer
      audiences: [ github.audience ]
      subject: github.subject
      description: 'The GitHub repo will sign in via a federated credential'
    }
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyvaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    sku: { name: 'standard', family: 'A' }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyvault
  name: secretName
  properties: {
    value: secretValue
  }
}

resource managedIdentityCanReadSecrets 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultRoleID['Key Vault Secrets User'], uami.id, keyvault.id)
  scope: keyvault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultRoleID['Key Vault Secrets User'])
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output uami object = {
  tenant_id: subscription().tenantId
  client_id: uami.properties.clientId
}
