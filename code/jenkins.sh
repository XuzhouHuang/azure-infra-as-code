#!/bin/bash

# switch to workspace directory and create deployment folder
cd $WORKSPACE ; mkdir deployment; cd deployment
DeploymentID=$(date +%Y%m%d%H%M)

# pass $(date +%Y%m%d%H%M) as DeployID to build deployment env folder
pwsh -file $WORKSPACE/code/linux/Create-ArmEnvironment.ps1 -DeployID $DeploymentID
cd $DeploymentID

# creat resouce group
pwsh -file $WORKSPACE/code/linux/Create-ArmResourceGroup.ps1

# Create KeyVault and Secrets. resource should retrieve Password and other secret from Key Vault
pwsh -file $WORKSPACE/code/linux/Create-ArmKVParam.ps1 

# Create SQL Server and SQL DB
pwsh -file $WORKSPACE/code/linux/Create-ArmSQLParam.ps1

# Create virtual network
pwsh -file $WORKSPACE/code/linux/Create-ArmVNETParam.ps1    

# Create virtual network NSGs
pwsh -file $WORKSPACE/code/linux/Create-ArmNSGParam.ps1 

# Create virtual network UDRs
pwsh -file $WORKSPACE/code/linux/Create-ArmUDRParam.ps1 

# Create Service Fabric Cluster
pwsh -file $WORKSPACE/code/linux/Create-ArmSFParam.ps1           

# Create Virtual Machines group
pwsh -file $WORKSPACE/code/linux/Create-ArmVMParam.ps1
