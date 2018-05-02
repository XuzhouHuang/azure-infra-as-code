# azure-infra-as-code

The project is to manage Azure infrastructure using ARM Template, Azure Building Block, Azure CLI and PowerShell.
Target cloud is AzureChinaCloud and tested. 
AzureCloud should also work but need further test


## Workflow

> a. Code change (Excel) commit to Github

> b. Github Jenkins Webhook Plugin 

> c. Jenkins Workitem 

> d. PS to parse input Excel doc

> e. Az & AzBB & ARM Template for resource provision. 

> f. Status Report


## Jenkins (Linux)

|Module          |Function                  |LINK                                                          |
|----------------|--------------------------|--------------------------------------------------------------|
|Azure CLI       |SPN login, ARM Template   |                                                              |
|AzBB            |AzBB template for IaaS    |                                                              |
|PowerShell      |logic & script control    |https://docs.microsoft.com/en-us/powershell/azure/install-azurermps-maclinux                             |
|ImportExcel     |parse user input          |                                                              |




## Jenkins (Windows)
Similar as Jenkins on Linux. 
