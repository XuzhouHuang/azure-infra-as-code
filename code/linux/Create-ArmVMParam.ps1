Import-Module "./Module.psm1"

# VM object is supported in AzBB. but consider a customer special request for disk/vm name, using a customized template
$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"
$vmSheet = Import-Excel -Path $excelSheet -WorksheetName VM -DataOnly

$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly 
$subscriptionId = $environmentSheet[1].SubscriptionID

#copy update tempalte from template forlder to current folder.
$vmARMTemplate = "../../arm/vmGroup/VMTemplate.json"
Copy-Item -Path $vmARMTemplate -Destination "./VMTemplate.json"
$vmARMTemplate = "$deployPath/VMTemplate.json"

# clearn up empty line and empty column
"#### azure vm provision command"| Out-File -Encoding utf8 "$deployPath\az-vm-create-cmd.bat"
for ($i = 0; $i -lt $vmSheet.Count; $i++) 
{
    $vmJson = ConvertTo-Json -InputObject $vmSheet[$i]
    $vmObject = $vmJson | ConvertFrom-Json

    $vmObject | ForEach-Object {
        # Get array of names of object properties that can be cast to boolean TRUE
        # PSObject.Properties - https://msdn.microsoft.com/en-us/library/system.management.automation.psobject.properties.aspx
        $NonEmptyProperties = $_.psobject.Properties | Where-Object {$_.Value} | Select-Object -ExpandProperty Name
        # Convert object to JSON with only non-empty properties
        $vmObjectParam = $_ | Select-Object -Property $NonEmptyProperties 
    }

    $VMObjectHash = $vmObjectParam | ConvertTo-Hashtable 

    $keyvaultRG = $VMObjectHash.keyvaultRG
    $keyvault = $VMObjectHash.keyvault
    $Secret = $VMObjectHash.Secret

    $userPassword = @{ reference = @{keyVault = @{id = "/subscriptions/$subscriptionId/resourceGroups/$keyvaultRG/providers/Microsoft.KeyVault/vaults/$keyvault"}; secretName = $Secret} }

    # in powershell, we can use HashObject direclty. but need to convert it to parameter file for Az command to use.

    $RGName = $VMObjectHash.ResourceGroup; $VMObjectHash.Remove('ResourceGroup')
    $vmParamFileName = "arm-vm-" + $VMObjectHash.vmName + "-Param.json"

    $parameterFile = @{
            contentVersion = "1.0.0.0";
            parameters = @{
                vmName = @{
                    value = $VMObjectHash.vmName
                }
                vmSize = @{
                    value = $VMObjectHash.vmSize
                }
                dataDiskNumber = @{
                    value = [int]$VMObjectHash.dataDiskNumber
                }
                numberOfInstances = @{
                    value = [int]$VMObjectHash.numberOfInstances
                }
                indexFrom = @{
                    value = [int]$VMObjectHash.indexFrom
                }
                imageUri = @{
                    value = $VMObjectHash.imageUri
                }
                vNetRG = @{
                    value = $VMObjectHash.vNetRG
                }
                subnetName = @{
                    value = $VMObjectHash.SubnetName
                }
                vNetName = @{
                    value = $VMObjectHash.vNetName
                }
                vmIPScope = @{
                    value = $VMObjectHash.vmIPScope
                }
                availabilitySetName = @{
                    value = $VMObjectHash.availabilitySetName
                }
                adminUsername = @{
                    value = $VMObjectHash.adminUsername
                }
                adminPassword = $userPassword
                vmDiagnosticStor = @{
                    value = $VMObjectHash.vmDiagnosticStor
                }
            }
        }
    $parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
    $parameterFile = $parameterFile.Replace("null", "")
    $parameterFile | Out-File -Encoding utf8 "$deployPath/$vmParamFileName"
    
    $azCommand = "az group deployment create -g " + $RGName + " --template-file $vmARMTemplate --parameters " + " @$deployPath/$vmParamFileName"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-vm-create-cmd.bat"
}

###########################################
