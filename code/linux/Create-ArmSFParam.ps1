Import-Module "./Module.psm1"

$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"
$sfARMTemplate = "../../arm/ServiceFabric/SF-1Nodetype-Linux.json"

# Service Fabric is not available in AzBB. We use use our own ARM Template to Generate a Parameter Json. 
$sfSheet = Import-Excel -Path $excelSheet -WorksheetName ServiceFabric

# read input parameter
$RG = $sfSheet[0].C; $Location = $sfSheet[0].D
$clusterDnsName = $sfSheet[1].C
$nt0InstanceCount = $sfSheet[2].C; $vmNodeType0Size = $sfSheet[2].D
$sfLogStorageAccount = $sfSheet[3].C; $LogStorAccountSKU = $sfSheet[3].D
$pipName = $sfSheet[4].C; $InternetAccessPort1 = $sfSheet[4].D; $InternetAccessPort2 = $sfSheet[4].E
$vNetResourceGroup = $sfSheet[5].C; $vNetName = $sfSheet[5].D; $subnetName = $sfSheet[5].E
$adminUsername = $sfSheet[6].C; $adminPassword = $sfSheet[6].D
$securityLevel = $sfSheet[7].C; $sourceVaultValue = $sfSheet[7].D; $certificateUrlValue= $sfSheet[7].E; $certificateThumbprint= $sfSheet[7].F

$parameterFile = @{
  contentVersion = "1.0.0.0";
  parameters = @{
                    clusterDnsName = @{
                        value = $clusterDnsName
                    }
                    adminUsername = @{
                        value = $adminUsername
                    }
                    adminPassword = @{
                        value = $adminPassword
                    }
                    certificateThumbprint = @{
                        value = $certificateThumbprint
                    }
                    certificateUrlValue = @{
                        value = $certificateUrlValue
                    }
                    sourceVaultValue = @{
                        value = $sourceVaultValue
                    }
                    pipName = @{
                        value = $pipName
                    }
                    vNetResourceGroup = @{
                        value = $vNetResourceGroup
                    }
                    vNetName = @{
                        value = $vNetName
                    }
                    subnetName = @{ 
                        value = $subnetName
                    }
                    sfLogStorageAccount = @{
                        value = $sfLogStorageAccount
                    }
            }
}
$parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
$parameterFile = $parameterFile.Replace("null", "")

$parameterFile | Out-File -Encoding utf8 "$deployPath/sf-$clusterDnsName-param.json"
"### azure service fabric provision command" | Out-File -Encoding utf8 "$deployPath/az-sf-create-cmd.bat"
"az group deployment create -g " + $RG + " --template-file " + $sfARMTemplate + " --parameters @$deployPath/sf-$clusterDnsName-param.json" | Out-File -Encoding utf8 -Append "$deployPath/az-sf-create-cmd.bat"

