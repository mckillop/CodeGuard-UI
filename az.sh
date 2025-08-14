subId=$(az account show --query id --output tsv)
env="test"
proj="cgui"
location="australiasoutheast"
rg="$proj-$env-rg-$location"
cosmosDbAc="$proj-$env-cosmos-$location"
cosmosDbDb="db"
funcApp="$proj-$env-funcapp-$location"
storageAc="$proj$env$storage$location"
storageAc="${storageAc:0:24}"
az group create --name $rg --location $location
az cosmosdb create \
  --name $cosmosDbAc \
  --resource-group $rg \
  --locations regionName=$location failoverPriority=0 isZoneRedundant=False \
  --default-consistency-level Eventual \
  --capabilities EnableServerless
az cosmosdb sql database create \
  --account-name $cosmosDbAc \
  --resource-group $rg \
  --name $cosmosDbDb
az cosmosdb sql container create \
  --resource-group $rg \
  --account-name $cosmosDbAc \
  --database-name $cosmosDbDb \
  --name userConfig \
  --partition-key-path "/atomsphereEmail"  \
  --ttl -1
az cosmosdb sql container create \
  --resource-group $rg \
  --account-name $cosmosDbAc \
  --database-name $cosmosDbDb \
  --name codeguardAccessToken \
  --partition-key-path "/clientId" \
  --ttl -1
az cosmosdb sql container create \
  --resource-group $rg \
  --account-name $cosmosDbAc \
  --database-name $cosmosDbDb \
  --name reportExecution \
  --partition-key-path "/clientId" \
  --ttl -1
az cosmosdb sql container create \
  --resource-group $rg \
  --account-name $cosmosDbAc \
  --database-name $cosmosDbDb \
  --name cache \
  --partition-key-path "/atomsphereEmail" \
  --ttl -1  
az storage account create \
  --name $storageAc \
  --location $location \
  --resource-group $rg \
  --sku Standard_LRS \
  --kind StorageV2
az storage container create \
  --name reports \
  --account-name $storageAc \
  --auth-mode login
az functionapp create \
  --name $funcApp \
  --resource-group $rg \
  --storage-account $storageAc \
  --consumption-plan-location $location \
  --functions-version 4 \
  --runtime dotnet-isolated \
  --os-type Linux \
storageKey=$(az storage account keys list \
  --resource-group $rg \
  --account-name $storageAc \
  --query "[0].value" \
  --output tsv)
az functionapp config appsettings set \
  --name $funcApp \
  --resource-group $rg \
  --settings storageKey=$storageKey  
