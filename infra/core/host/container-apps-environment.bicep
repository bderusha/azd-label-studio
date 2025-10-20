param name string
param location string = resourceGroup().location
param tags object = {}

param daprEnabled bool = false
param logAnalyticsWorkspaceName string
param applicationInsightsName string = ''
param storageAccountName string = ''
param containerName string = ''

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIInstrumentationKey: daprEnabled && !empty(applicationInsightsName) ? applicationInsights.properties.InstrumentationKey : ''
  }
}

// Note: Blob storage mounting not configured here
// The container app will access blob storage directly via managed identity and Azure SDK

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if (!empty(storageAccountName)) {
  name: storageAccountName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (daprEnabled && !empty(applicationInsightsName)){
  name: applicationInsightsName
}

output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
output name string = containerAppsEnvironment.name
