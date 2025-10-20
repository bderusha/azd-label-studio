# Quick Start Guide

## Prerequisites

1. Install Azure Developer CLI:
   ```bash
   # macOS/Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   
   # Windows
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   ```

2. Install Docker Desktop (for building the image locally)

3. Have an Azure subscription

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

Edit `infra/api.bicep`, add to the `app` module:
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

Edit `infra/api.bicep`:
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

## Troubleshooting

### Deployment Fails

**Check deployment logs:**
```bash
azd monitor --logs
```

**Try a different region:**
```bash
azd down
azd up  # Select different location
```

### Can't Access URL

**Verify the app is running:**
```bash
az containerapp show --name <name> --resource-group <rg> --query properties.runningStatus
```

**Check ingress configuration:**
```bash
az containerapp show --name <name> --resource-group <rg> --query properties.configuration.ingress
```

### Data Not Persisting

**Verify storage mount:**
1. Go to Azure Portal
2. Open your Container App
3. Go to "Volumes" section
4. Verify the volume is mounted at `/label-studio/data`

**Check from inside container:**
```bash
az containerapp exec --name <name> --resource-group <rg> --command "ls -la /label-studio/data"
```

### Out of Memory

**Increase memory in `infra/api.bicep`:**
```bicep
containerMemory: '4.0Gi'
```

Then:
```bash
azd provision
```

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

## Multiple Environments

### Create Dev Environment
```bash
azd env new dev
azd up
```

### Create Prod Environment
```bash
azd env new prod
azd up
```

### Switch Between Environments
```bash
azd env select dev
azd env select prod
```

### List Environments
```bash
azd env list
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/azure-dev.yml`:
```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install azd
        uses: Azure/setup-azd@v0.1.0
      
      - name: Login to Azure
        uses: Azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy
        run: azd up --no-prompt
        env:
          AZURE_ENV_NAME: ${{ vars.AZURE_ENV_NAME }}
          AZURE_LOCATION: ${{ vars.AZURE_LOCATION }}
          AZURE_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

## Getting Help

- [Label Studio Docs](https://labelstud.io/guide/)
- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)
- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

## Next Steps

1. ✅ Deploy with `azd up`
2. ✅ Access Label Studio at the provided URL
3. ✅ Create your first project
4. ✅ Start annotating!
5. ✅ Configure custom ML backends (optional)
6. ✅ Set up authentication (optional)
7. ✅ Integrate with your data pipeline (optional)

Enjoy using Label Studio on Azure! 🎉
