# Label Studio on Azure Container Apps

This project deploys [Label Studio](https://labelstud.io/) to Azure Container Apps using the Azure Developer CLI (azd).This repository includes a simple Python FastAPI app with a single route that returns JSON.

You can use this project as a starting point for your own APIs.

## Features

The repository is designed for use with [Docker containers](https://www.docker.com/), both for local development and deployment, and includes infrastructure files for deployment to [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/overview). 🐳

- **Label Studio**: Latest version deployed from official Docker Hub image

- **Persistent Storage**: Azure File Share mounted for data persistenceThe code istested with [pytest](https://docs.pytest.org/en/7.2.x/),

- **Container Apps**: Serverless container hosting with automatic scalinglinted with [ruff](https://github.com/charliermarsh/ruff), and formatted with [black](https://black.readthedocs.io/en/stable/).

- **Monitoring**: Application Insights and Log Analytics integrationCode quality issues are all checked with both [pre-commit](https://pre-commit.com/) and Github actions.



## Prerequisites## Opening the project



- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)This project has [Dev Container support](https://code.visualstudio.com/docs/devcontainers/containers), so it will be be setup automatically if you open it in Github Codespaces or in local VS Code with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

- [Docker](https://docs.docker.com/get-docker/)

- Azure subscriptionIf you're not using one of those options for opening the project, then you'll need to:



## Getting Started1. Create a [Python virtual environment](https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments) and activate it.



### 1. Login to Azure2. Install the requirements:



```bash    ```shell

azd auth login    python3 -m pip install -r requirements-dev.txt

```    ```



### 2. Deploy to Azure3. Install the pre-commit hooks:



```bash    ```shell

azd up    pre-commit install

```    ```



This command will:## Local development

1. Prompt you for an environment name (e.g., "label-studio-prod")

2. Ask you to select an Azure subscription and location1. Run the local server:

3. Provision all Azure resources (Resource Group, Container Apps Environment, Storage Account, etc.)

4. Build and push the Label Studio Docker image to Azure Container Registry    ```shell

5. Deploy the container to Azure Container Apps    fastapi dev src/api/main.py

6. Configure persistent storage for Label Studio data    ```



The deployment typically takes 5-10 minutes.2. Click 'http://127.0.0.1:8000' in the terminal, which should open a new tab in the browser.



### 3. Access Label Studio3. Try the API at '/generate_name' and try passing in a parameter at the end of the URL, like '/generate_name?starts_with=N'.



After deployment completes, azd will output the URL for your Label Studio instance:### Local development with Docker



```You can also run this app with Docker, thanks to the `Dockerfile`.

LABEL_STUDIO_URL: https://your-app.region.azurecontainerapps.io

```You need to either have Docker Desktop installed or have this open in Github Codespaces for these commands to work. ⚠️ If you're on an Apple M1/M2, you won't be able to run `docker` commands inside a Dev Container; either use Codespaces or do not open the Dev Container.



Visit this URL in your browser to start using Label Studio.1. Build the image:



## Architecture    ```shell

    docker build --tag fastapi-app ./src

- **Azure Container Apps**: Hosts the Label Studio container    ```

- **Azure Container Registry**: Stores the container image

- **Azure Storage Account**: Provides persistent file storage via Azure Files2. Run the image:

- **Azure Monitor**: Log Analytics and Application Insights for monitoring

    ```shell

## Data Persistence    docker run --publish 3100:3100 fastapi-app

    ```

Label Studio data is persisted in an Azure File Share mounted at `/label-studio/data` in the container. This includes:

- Project configurations### Deployment

- Annotations

- Uploaded media filesThis repo is set up for deployment on Azure Container Apps using the configuration files in the `infra` folder.

- Database files

This diagram shows the architecture of the deployment:

## Customization

![Diagram of app architecture: Azure Container Apps environment, Azure Container App, Azure Container Registry, Container, and Key Vault](readme_diagram.png)

### Change Label Studio Version

Steps for deployment:

Edit `Dockerfile.azd` and change the version tag:

1. Sign up for a [free Azure account](https://azure.microsoft.com/free/) and create an Azure Subscription.

```dockerfile2. Install the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd). (If you open this repository in Codespaces or with the VS Code Dev Containers extension, that part will be done for you.)

FROM heartexlabs/label-studio:1.9.03. Login to Azure:

```

    ```shell

Then run:    azd auth login

    ```

```bash

azd deploy4. Provision and deploy all the resources:

```

    ```shell

### Adjust Resources    azd up

    ```

Edit `infra/api.bicep` to change CPU, memory, or replica settings:

    It will prompt you to provide an `azd` environment name (like "fastapi-app"), select a subscription from your Azure account, and select a location (like "eastus"). Then it will provision the resources in your account and deploy the latest code. If you get an error with deployment, changing the location can help, as there may be availability constraints for some of the resources.

```bicep

containerCpuCoreCount: '1.0'5. When `azd` has finished deploying, you'll see an endpoint URI in the command output. Visit that URI, and you should see the API output! 🎉

containerMemory: '2.0Gi'6. When you've made any changes to the app code, you can just run:

containerMinReplicas: 1

containerMaxReplicas: 1    ```shell

```    azd deploy

    ```

### Configure Environment Variables

### Costs

Add environment variables in `infra/api.bicep` in the `app` module parameters:

Pricing varies per region and usage, so it isn't possible to predict exact costs for your usage.

```bicepThe majority of the Azure resources used in this infrastructure are on usage-based pricing tiers.

module app 'core/host/container-app-upsert.bicep' = {However, Azure Container Registry has a fixed cost per registry per day.

  name: '${serviceName}-container-app-module'

  params: {You can try the [Azure pricing calculator](https://azure.com/e/9f8185b239d240b398e201078d0c4e7a) for the resources:

    // ... existing params ...

    env: [- Azure Container App: Consumption tier with 0.5 CPU, 1GiB memory/storage. Pricing is based on resource allocation, and each month allows for a certain amount of free usage. [Pricing](https://azure.microsoft.com/pricing/details/container-apps/)

      {- Azure Container Registry: Basic tier. [Pricing](https://azure.microsoft.com/pricing/details/container-registry/)

        name: 'LABEL_STUDIO_USERNAME'- Log analytics: Pay-as-you-go tier. Costs based on data ingested. [Pricing](https://azure.microsoft.com/pricing/details/monitor/)

        value: 'admin@localhost'

      }⚠️ To avoid unnecessary costs, remember to take down your app if it's no longer in use,

      {either by deleting the resource group in the Portal or running `azd down`.

        name: 'LABEL_STUDIO_PASSWORD'

        value: 'changeme'

      }## Getting help

    ]

  }If you're working with this project and running into issues, please post in **Discussions**.

}
```

## Monitoring

View logs and metrics:

```bash
azd monitor --logs
```

Or visit the Azure Portal to view:
- Application Insights for application metrics and traces
- Log Analytics for container logs
- Container App metrics for resource usage

## Clean Up

To delete all Azure resources:

```bash
azd down
```

## Costs

Pricing varies per region and usage. The resources used in this infrastructure:

- **Azure Container Apps**: Consumption tier with 1 CPU, 2GiB memory. [Pricing](https://azure.microsoft.com/pricing/details/container-apps/)
- **Azure Container Registry**: Basic tier. [Pricing](https://azure.microsoft.com/pricing/details/container-registry/)
- **Azure Storage Account**: Standard LRS with File Share (1TB quota). [Pricing](https://azure.microsoft.com/pricing/details/storage/files/)
- **Log Analytics**: Pay-as-you-go tier. [Pricing](https://azure.microsoft.com/pricing/details/monitor/)

💡 Try the [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) to estimate costs.

⚠️ To avoid unnecessary costs, remember to run `azd down` when you're done using the application.

## Troubleshooting

### View deployment logs

```bash
azd monitor --logs
```

### Check container app status

```bash
az containerapp show --name <app-name> --resource-group <resource-group> --query properties.runningStatus
```

### Access container logs directly

```bash
az containerapp logs show --name <app-name> --resource-group <resource-group> --follow
```

### Common Issues

**Deployment fails with "location not available"**: Try a different Azure region during `azd up`.

**Container app won't start**: Check the logs with `azd monitor --logs` to see container startup errors.

**Data not persisting**: Verify the storage mount is configured correctly in the Azure Portal under the Container App's "Volumes" section.

## Migrating from bootstrap.sh

If you were previously using the `bootstrap.sh` script, this azd project provides the same functionality with these improvements:

- ✅ Infrastructure as Code (Bicep) instead of imperative CLI commands
- ✅ Automatic environment management and configuration
- ✅ Easy redeployment and updates with `azd deploy`
- ✅ Integrated monitoring and logging
- ✅ Simplified cleanup with `azd down`
- ✅ Container Registry for custom image management

The deployment creates the same resources:
- Resource Group
- Container Apps Environment  
- Storage Account with File Share mounted at `/label-studio/data`
- Container App running Label Studio
- Container Registry (for building and hosting the image)
- Log Analytics and Application Insights

**To migrate existing data**: Copy files from your old storage account file share to the new one after deployment using Azure Storage Explorer or `az storage` commands.

## Additional Resources

- [Label Studio Documentation](https://labelstud.io/guide/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Files Documentation](https://learn.microsoft.com/azure/storage/files/)

## Getting Help

If you run into issues:
1. Check the [Label Studio GitHub Issues](https://github.com/heartexlabs/label-studio/issues)
2. Review [Azure Container Apps troubleshooting](https://learn.microsoft.com/azure/container-apps/troubleshooting)
3. Post in the project **Discussions**
