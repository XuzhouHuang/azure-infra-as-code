az cloud list --output table 
az cloud set -n AzureChinaCloud 
az login --service-principal -u 47a639b4-f614-4e56-a2bf-6979f64ce5cf -p C:\kangxh\AzureLabs\Certs\mc-allenk-automation-spn.pem --tenant 954ddad8-66d7-47a8-8f9f-1316152d9587
az account list --output table
az account set -s c4013028-2728-46b8-acf1-e397840c4344


az group create --name infra-as-code --location ChinaNorth
az group create --name infra-as-code-vm --location ChinaNorth
az group create --name infra-as-code-sf --location ChinaNorth
az group create --name infra-as-code-db --location ChinaNorth


azbb -c AzureChinaCloud -s c4013028-2728-46b8-acf1-e397840c4344 -g infra-as-code -l ChinaNorth  -p /data/infra-as-code/deployment/201804251425/vnet-vnet1-param.json --deploy


az group deployment create -g infra-as-code-vm --template-file /data/infra-as-code/arm/VMGroup/azuredeploy.json --parameters @/data/infra-as-code/deployment/201804251425/vm-arm-web-Param.json
az group deployment create -g infra-as-code-vm --template-file /data/infra-as-code/arm/VMGroup/azuredeploy.json --parameters @/data/infra-as-code/deployment/201804251425/vm-arm-app-Param.json

az group deployment create -g infra-as-code-sf --template-file /data/infra-as-code/arm/ServiceFabric/azuredeploy.json--parameters @/data/infra-as-code/deployment/201804251425/sf-mc-sf-param.json
