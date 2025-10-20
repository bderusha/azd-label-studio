RESOURCE_GROUP="label-studio-rg"
ENVIRONMENT_NAME="label-studio-cae"
LOCATION="eastus"
STORAGE_ACCOUNT_NAME="labelstudiosa$RANDOM"
STORAGE_SHARE_NAME="labelstudiofileshare"
STORAGE_MOUNT_NAME="labelstudiostoragemount"
CONTAINER_APP_NAME="label-studio-app"
LABEL_STUDIO_IMAGE="heartexlabs/label-studio:latest"


az extension add -n containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION --query "properties.provisioningState"

# Create Container Apps Environment
az containerapp env create --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --location "$LOCATION" --query "properties.provisioningState"

# Create Storage Account
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT_NAME --location "$LOCATION" --kind StorageV2 --sku Standard_LRS --enable-large-file-share --query provisioningState

# Create File Share
az storage share-rm create --resource-group $RESOURCE_GROUP --storage-account $STORAGE_ACCOUNT_NAME --name $STORAGE_SHARE_NAME --quota 1024 --enabled-protocols SMB --output table

STORAGE_ACCOUNT_KEY=`az storage account keys list -n $STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv`

# Create Storage Mount
az containerapp env storage set --access-mode ReadWrite --azure-file-account-name $STORAGE_ACCOUNT_NAME --azure-file-account-key $STORAGE_ACCOUNT_KEY --azure-file-share-name $STORAGE_SHARE_NAME --storage-name $STORAGE_MOUNT_NAME --name $ENVIRONMENT_NAME --resource-group $RESOURCE_GROUP --output table

# Create Container App with Storage Mount
az containerapp create --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT_NAME --image $LABEL_STUDIO_IMAGE --min-replicas 1 --max-replicas 1 --target-port 80 --ingress external --query properties.configuration.ingress.fqdn

# Mount the storage to the container app
az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --output yaml > app.yaml

# Replace the "volumes" section of the YAML file with:
# volumes:
#   - name: label-studio-file-volume
#     storageName: $STORAGE_MOUNT_NAME
#     storageType: AzureFile

yq eval '.properties.template.volumes = [{"name": "label-studio-file-volume", "storageName": "'$STORAGE_MOUNT_NAME'", "storageType": "AzureFile"}]' -i app.yaml

# Replace the "volumeMounts" section of the YAML file with:
# volumeMounts:
#   - name: label-studio-file-volume
#     mountPath: /label-studio/data
yq eval '.properties.template.containers[0].volumeMounts = [{"name": "label-studio-file-volume", "mountPath": "/label-studio/data"}]' -i app.yaml

# Update the container app with the modified YAML file
az containerapp update --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --yaml app.yaml --output table