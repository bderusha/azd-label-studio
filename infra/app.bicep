param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param serviceName string = 'app'
param appExists string = 'false'
param env array = []
param command array = []
param args array = []
param imageName string = ''
param storageAccountName string = ''
param storageContainerName string = ''

var exists = bool(appExists)

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppsEnvironmentName
}

module app 'core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityName: appIdentity.name
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    imageName: imageName
    env: [
      {
        name: 'AZURE_STORAGE_ACCOUNT_NAME'
        value: storageAccountName
      }
      {
        name: 'AZURE_STORAGE_CONTAINER_NAME'
        value: storageContainerName
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: appIdentity.properties.clientId
      }
      {
        name: 'CSRF_TRUSTED_ORIGINS'
        value: 'https://${name}.${containerAppsEnvironment.properties.defaultDomain}'
      }
      ...env
    ]
    command: command
    args: args
    targetPort: 8080
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    containerMinReplicas: 1
    containerMaxReplicas: 1
  }
}

output SERVICE_APP_IDENTITY_PRINCIPAL_ID string = appIdentity.properties.principalId
output SERVICE_APP_IDENTITY_NAME string = appIdentity.name
output SERVICE_APP_NAME string = app.outputs.name
output SERVICE_APP_URI string = app.outputs.uri
output SERVICE_APP_IMAGE_NAME string = app.outputs.imageName
