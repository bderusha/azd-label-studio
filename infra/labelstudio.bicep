param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param serviceName string = 'label-studio'
param exists bool
param labelStudioImage string = 'heartexlabs/label-studio:latest'
param storageAccountName string = ''
param storageContainerName string = ''
param labelStudioDisableSignupWithoutLink string = 'true'
param labelStudioUsername string = 'admin@localhost'
param labelStudioPassword string = 'password'

resource apiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
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
    identityName: apiIdentity.name
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    imageName: labelStudioImage
    env: [
      {
        name: 'LABEL_STUDIO_DISABLE_SIGNUP_WITHOUT_LINK'
        value: labelStudioDisableSignupWithoutLink
      }
      {
        name: 'LABEL_STUDIO_USERNAME'
        value: labelStudioUsername
      }
      {
        name: 'LABEL_STUDIO_PASSWORD'
        value: labelStudioPassword
      }
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
        value: apiIdentity.properties.clientId
      }
      {
        name: 'CSRF_TRUSTED_ORIGINS'
        value: 'https://${name}.${containerAppsEnvironment.properties.defaultDomain}'
      }
    ]
    targetPort: 8080
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    containerMinReplicas: 1
    containerMaxReplicas: 1
  }
}

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = apiIdentity.properties.principalId
output SERVICE_API_NAME string = app.outputs.name
output SERVICE_API_URI string = app.outputs.uri
output SERVICE_API_IMAGE_NAME string = app.outputs.imageName
