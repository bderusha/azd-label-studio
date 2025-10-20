# Migration from bootstrap.sh to Azure Developer CLI (azd)

## Overview

This document explains the conversion from the imperative `bootstrap.sh` script to a declarative Azure Developer CLI (azd) project using Bicep infrastructure-as-code.

## Key Changes

### 1. Project Structure

**Added Files:**
- `Dockerfile.azd` - Simple Dockerfile that pulls the official Label Studio image
- `infra/core/storage/storage-account.bicep` - Storage account and file share provisioning
- `.dockerignore` - Optimizes Docker build context
- Updated `README.md` - Complete documentation for the azd project

**Modified Files:**
- `azure.yaml` - Configured for Label Studio service with Docker support
- `infra/main.bicep` - Added storage account module and updated service name
- `infra/main.parameters.json` - Updated service name from `api` to `label-studio`
- `infra/api.bicep` - Configured for Label Studio (port 8080, volume mounts, increased resources)
- `infra/core/host/container-apps.bicep` - Added storage account parameters
- `infra/core/host/container-apps-environment.bicep` - Added storage mount configuration
- `infra/core/host/container-app-upsert.bicep` - Added volume mount support
- `infra/core/host/container-app.bicep` - Added volume mount support

### 2. Infrastructure Components

The azd project provisions these resources (matching bootstrap.sh):

| Resource | bootstrap.sh | azd Project | Notes |
|----------|-------------|-------------|-------|
| Resource Group | ✅ | ✅ | Same functionality |
| Container Apps Environment | ✅ | ✅ | Same functionality + integrated monitoring |
| Storage Account | ✅ | ✅ | Same SKU (Standard_LRS) |
| File Share | ✅ | ✅ | Same configuration (1TB quota, SMB) |
| Storage Mount | ✅ | ✅ | Mounted at `/label-studio/data` |
| Container App | ✅ | ✅ | Runs Label Studio with storage |
| Container Registry | ❌ | ✅ | **New** - for building custom images |
| Log Analytics | ❌ | ✅ | **New** - for centralized logging |
| Application Insights | ❌ | ✅ | **New** - for monitoring (optional) |

### 3. Configuration Mapping

#### Container Configuration

**bootstrap.sh:**
```bash
LABEL_STUDIO_IMAGE="heartexlabs/label-studio:latest"
--target-port 80
--min-replicas 1
--max-replicas 1
```

**azd (in `infra/api.bicep`):**
```bicep
targetPort: 8080  # Label Studio's actual port
containerCpuCoreCount: '1.0'
containerMemory: '2.0Gi'
containerMinReplicas: 1
containerMaxReplicas: 1
```

#### Storage Mount

**bootstrap.sh:**
```bash
volumes:
  - name: label-studio-file-volume
    storageName: $STORAGE_MOUNT_NAME
    storageType: AzureFile

volumeMounts:
  - name: label-studio-file-volume
    mountPath: /label-studio/data
```

**azd (in `infra/api.bicep`):**
```bicep
volumeMounts: [
  {
    volumeName: 'labelstudiodata'
    mountPath: '/label-studio/data'
  }
]
volumes: [
  {
    name: 'labelstudiodata'
    storageName: 'labelstudiostorage'
    storageType: 'AzureFile'
  }
]
```

### 4. Workflow Comparison

**bootstrap.sh Workflow:**
```bash
# Manual steps required
az extension add -n containerapp --upgrade
az provider register --namespace Microsoft.App
az group create ...
az containerapp env create ...
az storage account create ...
az storage share-rm create ...
az containerapp create ...
# Manual YAML editing with yq
az containerapp update --yaml app.yaml
```

**azd Workflow:**
```bash
# Single command deployment
azd up

# Or separate steps
azd provision  # Create infrastructure
azd deploy     # Deploy application
```

### 5. Benefits of azd Approach

1. **Declarative Infrastructure**: Bicep files define desired state instead of imperative commands
2. **Idempotent**: Can run multiple times safely
3. **Version Control**: All infrastructure defined in code
4. **Environment Management**: Built-in support for multiple environments (dev, staging, prod)
5. **Integrated Tooling**: Works with VS Code, GitHub Actions, Azure DevOps
6. **Easy Updates**: `azd deploy` redeploys without recreating resources
7. **Clean Teardown**: `azd down` removes all resources
8. **Built-in Monitoring**: Automatic Log Analytics and Application Insights setup

### 6. Resource Naming

**bootstrap.sh** used environment variables:
```bash
RESOURCE_GROUP="label-studio-rg"
ENVIRONMENT_NAME="label-studio-cae"
STORAGE_ACCOUNT_NAME="labelstudiosa$RANDOM"
```

**azd** uses a systematic naming pattern:
```bicep
var resourceToken = toLower(uniqueString(subscription().id, name, location))
var prefix = '${name}-${resourceToken}'

// Examples:
// Resource Group: myenv-rg
// Container Apps Env: myenv-abc123-containerapps-env
// Storage Account: myenvabc123st
// Container Registry: myenvabc123registry
```

## Migration Steps

If you have an existing deployment from `bootstrap.sh`:

1. **Deploy new azd infrastructure:**
   ```bash
   azd up
   ```

2. **Copy data from old storage (optional):**
   ```bash
   # Get old storage key
   OLD_KEY=$(az storage account keys list -n labelstudiosa12345 -g label-studio-rg --query "[0].value" -o tsv)
   
   # Get new storage name from azd
   NEW_STORAGE=$(azd env get-values | grep AZURE_STORAGE_ACCOUNT_NAME | cut -d= -f2)
   NEW_KEY=$(az storage account keys list -n $NEW_STORAGE -g $(azd env get-values | grep RESOURCE_GROUP | cut -d= -f2) --query "[0].value" -o tsv)
   
   # Copy files using azcopy or Azure Storage Explorer
   ```

3. **Delete old infrastructure:**
   ```bash
   az group delete --name label-studio-rg
   ```

## Customization Examples

### Adding Environment Variables

Edit `infra/api.bicep`:

```bicep
module app 'core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    // ... existing params ...
    env: [
      {
        name: 'LABEL_STUDIO_LOCAL_FILES_SERVING_ENABLED'
        value: 'true'
      }
      {
        name: 'LABEL_STUDIO_LOCAL_FILES_DOCUMENT_ROOT'
        value: '/label-studio/data'
      }
    ]
  }
}
```

### Changing Label Studio Version

Edit `Dockerfile.azd`:

```dockerfile
FROM heartexlabs/label-studio:1.9.2
```

Then deploy:
```bash
azd deploy
```

### Scaling Configuration

Edit `infra/api.bicep`:

```bicep
containerMinReplicas: 2
containerMaxReplicas: 10
```

## Testing the Conversion

To validate the conversion works correctly:

```bash
# 1. Provision and deploy
azd up

# 2. Get the URL
azd env get-values | grep LABEL_STUDIO_URL

# 3. Visit the URL and verify Label Studio loads

# 4. Check logs
azd monitor --logs

# 5. Verify storage mount
az containerapp exec \
  --name <app-name> \
  --resource-group <rg-name> \
  --command "ls -la /label-studio/data"
```

## Troubleshooting

### Issue: Storage not mounting
**Solution**: Check that the storage account and file share exist, and verify the mount configuration in the Container App's "Volumes" section in Azure Portal.

### Issue: Container won't start
**Solution**: Run `azd monitor --logs` to see startup errors. Common issues:
- Port mismatch (should be 8080)
- Insufficient memory (needs at least 2Gi)
- Storage mount permissions

### Issue: Can't build Docker image
**Solution**: Ensure Docker is running locally. The azd build happens locally before pushing to ACR.

## Summary

The azd conversion provides the same Label Studio deployment as `bootstrap.sh` but with:
- ✅ Better maintainability through IaC
- ✅ Easier updates and redeployment
- ✅ Built-in monitoring and logging
- ✅ Environment management
- ✅ Integration with modern DevOps workflows

The trade-off is initial complexity of learning Bicep, but the long-term benefits far outweigh this.
