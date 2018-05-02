#Jenkins Server environment setup:

Install Azure CLI

Install Azure Building Block

Install Powershell

Import ImportExcel module
https://docs.microsoft.com/en-us/powershell/azure/install-azurermps-maclinux?view=azurermps-5.7.0


Install Azure PS Module # PowerShell module is not used as Azure PowerShell does not support certification based logon so far. 2018-4-25
==================================

/data/infra-as-code/[DateTime]/RGs/


===================================
#!/bin/bash

# switch to workspace directory
cd $WORKSPACE
cd /data/infra-as-code/

# az login with Mooncake SPN
az cloud list --output table 
az cloud set -n AzureChinaCloud 
az login --service-principal -u 47a639b4-f614-4e56-a2bf-6979f64ce5cf -p /data/infra-as-code/mc-allenk-automation-spn.pem --tenant 954ddad8-66d7-47a8-8f9f-1316152d9587
az account list --output table
az account set -s c4013028-2728-46b8-acf1-e397840c4344

# dump excel sheet data to Json files for parameter input
pwsh -file ./Create-ResourceGroupList.ps1     # dump the resource group list to az-rg-param.Json
pwsh -file ./Create-AzbbNetworkParam.ps1      # dump the virtual network configuration to azbb-vnet-param.json
pwsh -file ./Create-ArmServiceFabricParam.ps1 # dump the service fabric configuration to arm-sf-param.json
pwsh -file ./Create-ArmVMParam.ps1            # Dump the VM configuration to arm-vm-param.json

# Create all the resource group 

az group create --name infra-as-code --location ChinaNorth
azbb -c AzureChinaCloud -s c4013028-2728-46b8-acf1-e397840c4344 -l ChinaNorth -g infra-as-code -p /data/infra-as-code/userdata/azbb-vnet-param.json --deploy

az group create --name infra-as-code-sf --location ChinaNorth
az group deployment create -g infra-as-code-sf --template-file /data/infra-as-code/arm-template/ServiceFabric/azuredeploy.json --parameters @/data/infra-as-code/userdata/arm-sf-param.json

