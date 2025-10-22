# Label Studio on Azure Container Apps

This project deploys [Label Studio](https://labelstud.io/) to Azure Container Apps using the Azure Developer CLI (azd).

## Features

The repository is designed for use with [Docker containers](https://www.docker.com/) and includes infrastructure files for deployment to [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/overview). 🐳

- **Label Studio**: Latest version deployed from official Docker Hub image
- **Persistent Storage**: Azure Blob Storage
- **Container Apps**: Serverless container hosting with automatic scaling
- **Monitoring**: Application Insights and Log Analytics integration

## Prerequisites

1. Install Azure Developer CLI:
   ```bash
   # macOS/Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   
   # Windows
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   ```

2. Have an Azure subscription

## Deploy in 3 Steps

### 1. Login to Azure
```bash
azd auth login
```

### 2. Deploy Everything
```bash
azd up
```

You'll be prompted for:
- **Environment name**: A name for this deployment (e.g., `labelstudio-prod`)
- **Subscription**: Select your Azure subscription
- **Location**: Choose a region (e.g., `eastus`, `westus2`)

### 3. Access Your Application

After deployment completes (5-10 minutes), you'll see output like:

```
LABEL_STUDIO_URL: https://myenv-abc123-ca.kindgrass-12345678.eastus.azurecontainerapps.io
```

Visit that URL to start using Label Studio!

## Common Commands

### View Logs
```bash
azd monitor --logs
```

### Redeploy After Code Changes
```bash
azd deploy
```

### Update Infrastructure Only
```bash
azd provision
```

### View Environment Variables
```bash
azd env get-values
```

### Delete Everything
```bash
azd down
```

## What Gets Created?

Running `azd up` creates these resources in Azure:

1. **Resource Group** - Container for all resources
2. **Container Apps Environment** - Runtime environment for containers
3. **Storage Account** - Persistent storage with file share
4. **Container Registry** - Stores your Docker images
5. **Container App** - Runs Label Studio
6. **Log Analytics** - Centralized logging
7. **Application Insights** - Application monitoring

## Default Configuration

- **Label Studio Version**: Latest from Docker Hub
- **Port**: 8080
- **CPU**: 1.0 cores
- **Memory**: 2.0 GiB
- **Replicas**: 1 (fixed, no auto-scaling by default)
- **Data Mount**: Azure File Share at `/label-studio/data`
- **Storage**: 1TB file share quota

## Customization

### Change Label Studio Version

Edit `Dockerfile.azd`:
```dockerfile
FROM heartexlabs/label-studio:1.9.0
```

Deploy:
```bash
azd deploy
```

### Add Environment Variables

Edit `infra/labelstudio.bicep`, add to the `app` module:
```bicep
env: [
  {
    name: 'MY_ENV_VAR'
    value: 'my_value'
  }
]
```

Deploy:
```bash
azd provision  # Update infrastructure
```

### Adjust CPU/Memory

Edit `infra/labelstudio.bicep`:
```bicep
containerCpuCoreCount: '2.0'
containerMemory: '4.0Gi'
```

Deploy:
```bash
azd provision
```

## Monitoring

### View Real-time Logs
```bash
azd monitor --logs
```

### View in Azure Portal
1. Go to [portal.azure.com](https://portal.azure.com)
2. Find your resource group (named `<env-name>-rg`)
3. Open the Container App
4. Navigate to "Log stream" or "Metrics"

## Cost Management

### Estimate Costs

Main cost drivers:
- Container Apps: ~$50-100/month (1 vCPU, 2GB RAM, always on)
- Container Registry: ~$5/month (Basic tier)
- Storage: ~$20/month (1TB file share, low usage)
- Log Analytics: ~$5-10/month (low data ingestion)

**Total estimated**: ~$80-135/month

### Reduce Costs

1. **Use smaller container:**
   ```bicep
   containerCpuCoreCount: '0.5'
   containerMemory: '1.0Gi'
   ```

2. **Scale to zero when not in use:**
   ```bicep
   containerMinReplicas: 0
   containerMaxReplicas: 1
   ```

3. **Delete when not needed:**
   ```bash
   azd down
   ```

## CI/CD Integration

### GitHub Actions

Check out [.github/workflows/azure-dev.yml](.github/workflows/azure-dev.yml) for an example GitHub Actions workflow that deploys on push to `main`.

## Getting Help

- [Label Studio Docs](https://labelstud.io/guide/)
- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)
- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

