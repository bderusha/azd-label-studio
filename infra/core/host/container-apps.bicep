param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string
param logAnalyticsWorkspaceName string
param applicationInsightsName string = ''
param storageAccountName string = ''
param containerName string = ''

module containerAppsEnvironment 'container-apps-environment.bicep' = {
  name: '${name}-container-apps-environment'
  params: {
    name: containerAppsEnvironmentName
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    storageAccountName: storageAccountName
    containerName: containerName
  }
}

output defaultDomain string = containerAppsEnvironment.outputs.defaultDomain
output environmentName string = containerAppsEnvironment.outputs.name
