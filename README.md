# Public Image Deployment on Azure Container Apps (with Label Studio)

This project deploys an instance of [Label Studio](https://labelstud.io/) to Azure Container Apps using the Azure Developer CLI (azd), but this template can be adapted for any public docker image.

## Features

The repository is designed for use with [Docker containers](https://www.docker.com/) and includes infrastructure files for deployment to [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/overview). 🐳

- **Public Image**: This template deploys the latest version of Label Studio from the official Docker Hub image
- **Container Apps**: Serverless container hosting with automatic scaling
- **Persistent Storage**: Azure Blob Storage accessed with Managed Identity
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
- **Environment name**: A name for this deployment (e.g., `labelstudio`)
- **Subscription**: Select your Azure subscription
- **Location**: Choose a region (e.g., `eastus`, `westus2`)

### 3. Access Your Application

After deployment completes (5-10 minutes), you'll see output like:

```
(✓) Done: Deploying service app
  - Endpoint: https://myenv-abc123-ca.kindgrass-12345678.eastus.azurecontainerapps.io
```

Visit that URL to start using Label Studio!

## Common Commands

### View Logs
```bash
azd monitor --logs
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
3. **Storage Account** - Blob storage for Label Studio data persistence
4. **Container App** - Runs Label Studio (image pulled from Docker Hub)
5. **Log Analytics** - Centralized logging
6. **Application Insights** - Monitoring and telemetry
7. **Managed Identity** - Secure access to blob storage

## Default Configuration

- **Docker Image**: `heartexlabs/label-studio:latest`
- **Port**: 8080
- **CPU**: 1.0 cores
- **Memory**: 2.0 GiB
- **Replicas**: 1 (fixed, no auto-scaling by default)
- **Storage**: Azure Blob Storage container (`data`)
- **Label Studio Specific Settings**:
  - **Default Admin Username**: `admin@localhost`
  - **Default Admin Password**: `password`
  - **Signup Settings**: Signup without link disabled by default

## Customization

### Change Label Studio Version

Edit `azure.yaml` to specify a different image version:

```yaml
services:
  label-studio:
    host: containerapp
    image: heartexlabs/label-studio:1.9.0
```

Deploy:

```bash
azd deploy
```

### Configure Label Studio Settings

Customize Label Studio settings in `app.parameters.json`

`command` and `args` are the command-line options run against the container. `env` is for the environment variables set in the container.

```json
"command": {
   "value": [
      "label-studio"
   ]
},
"args": {
   "value": [
      "--log-level",
      "DEBUG"
   ]
},
"env": {
   "value": [
      {
      "name": "LABEL_STUDIO_USERNAME",
      "value": "admin@localhost"
      }
   ]
}
```

### Adjust CPU/Memory

Edit `infra/app.bicep`:
```bicep
containerCpuCoreCount: '2.0'
containerMemory: '4.0Gi'
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
- Storage: ~$5-20/month (blob storage, usage dependent)
- Log Analytics: ~$5-10/month (low data ingestion)

**Total estimated**: ~$60-130/month

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

