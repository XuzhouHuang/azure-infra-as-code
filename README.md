# azure-infra-as-code

The project to manager Azure Infra using ARM template, AzBB, Az and PowerShell. 

Target cloud is AzureChinaCloud and tested. 

Azure AzureCloud should also work no hard coded service end point. Need further test.

Workflow
=========
code change (Provision Request Excel) commit to Github 
  
    -> Github Jenkins Webhook Plugin 
    
      -> Jenkins Workitem 
      
        -> PS to parse input Excel doc
        
          -> Az & AzBB & Arm Template for resource povision. 
          
            -> Status Report

Jenkins (Linux)
================
Install Azure Cli
Install Azure Building Block
Install PowerShell for Linux
Import Azure PowerShell module for Linux: https://docs.microsoft.com/en-us/powershell/azure/install-azurermps-maclinux
Import ImportExcel Module

As running the provsion task using SPN, configure Azure SPN login for subscription. 
https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli.

Test Jenkins to ensure it works with Az spn logon 
