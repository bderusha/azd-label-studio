targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

param apiAppExists bool = false

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = { 'azd-env-name': name }

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

var prefix = '${name}-${resourceToken}'

// Storage account names must be between 3-24 chars, lowercase letters and numbers only
var storageAccountName = take(replace('${name}${resourceToken}st', '-', ''), 24)

// Storage Account for Label Studio data persistence
module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup
  params: {
    name: storageAccountName
    location: location
    tags: tags
    containerName: 'labelstudiodata'
  }
}

// Container apps host
module containerApps 'core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: resourceGroup
  params: {
    name: 'app'
    location: location
    tags: tags
    containerAppsEnvironmentName: '${prefix}-containerapps-env'
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    storageAccountName: storage.outputs.name
    containerName: storage.outputs.containerName
  }
}

// Label Studio app
module labelstudio 'labelstudio.bicep' = {
  name: 'label-studio-app'
  scope: resourceGroup
  params: {
    name: replace('${take(prefix,19)}-ca', '--', '-')
    location: location
    tags: tags
    identityName: '${prefix}-id-ls'
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    serviceName: 'label-studio'
    exists: apiAppExists
    storageAccountName: storage.outputs.name
    storageContainerName: storage.outputs.containerName
  }
}

// Grant Label Studio managed identity access to blob storage
module storageRoleAssignment 'core/security/storage-role-assignment.bicep' = {
  name: 'storage-role-assignment'
  scope: resourceGroup
  params: {
    principalId: labelstudio.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
    storageAccountName: storage.outputs.name
    // Storage Blob Data Contributor role
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }
}


module logAnalyticsWorkspace 'core/monitor/loganalytics.bicep' = {
  name: 'loganalytics'
  scope: resourceGroup
  params: {
    name: '${prefix}-loganalytics'
    location: location
    tags: tags
  }
}

output AZURE_LOCATION string = location
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output SERVICE_LABELSTUDIO_IDENTITY_PRINCIPAL_ID string = labelstudio.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
output SERVICE_LABELSTUDIO_NAME string = labelstudio.outputs.SERVICE_API_NAME
output SERVICE_LABELSTUDIO_URI string = labelstudio.outputs.SERVICE_API_URI
output SERVICE_LABELSTUDIO_IMAGE_NAME string = labelstudio.outputs.SERVICE_API_IMAGE_NAME
output AZURE_STORAGE_ACCOUNT_NAME string = storage.outputs.name
output LABEL_STUDIO_URL string = labelstudio.outputs.SERVICE_API_URI
