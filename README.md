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

## Trigger
|Commit Tag      |Function |
|----------------|-----------------------------------------------|
|DEPLOY          |deploy the resource to default subscription    |                                                              |
|DEMO            |Build the deployment batch file without deploy |                                                              |

## Jenkins (Linux)

|Component      |Function |
|----------------|-----------------------------------------------|
|Azure CLI       |Azure CLI -- SPN login, ARM Template for VM, DB   |                                                              |
|AzBB            |AzBB template to IaaS component, including vNet, NSG, UDR |
|PowerShell|logic & script control|
|Azure PowerShell| Azure PowerShell module for linux|
|ImportExcel | parse user input|

## Jenkins (Windows)
Similar as Jenkins on Linux. 


## Jenkins Trigger
when commit change, use DEPLOY as commit description, Jenkins workflow will tigger resource provision with this keyword
