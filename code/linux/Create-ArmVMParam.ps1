cd C:\kangxh\Infra-as-code\deployment\201804280801

Import-Module ".\Module.psm1"

# VM object is supported in AzBB. but consider a customer special request for disk/vm name, using a customized template
$deployPath = Convert-Path .
$excelSheet = $deployPath + "\AzureEnv.xlsx"
$vmSheet = Import-Excel -Path $excelSheet -WorksheetName VM -DataOnly
$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly 

if ([System.Environment]::OSversion.Platform -match "Win") {
    $subscriptionId = $environmentSheet[0].SubscriptionID
} else {
    $subscriptionId = $environmentSheet[1].SubscriptionID
}

#copy update tempalte from template forlder to current folder.
$vmARMTemplate = "..\..\arm\vmGroup\VMTemplate.json"
Copy-Item -Path $vmARMTemplate -Destination ".\VMTemplate.json"
$vmARMTemplate = "$deployPath\VMTemplate.json"

# clearn up empty line and empty column
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

    # in powershell, we can use HashObject direclty. but need to convert it to parameter file for Az command to use.

    $RGName = $VMObjectHash.ResourceGroup; $VMObjectHash.Remove('ResourceGroup')
    $vmParamFileName = "vm-" + $VMObjectHash.vmName + "-Param.json"

    $parameterFile = @{
            contentVersion = "1.0.0.0";
            parameters = @{
                vmName = @{
                    value = $VMObjectHash.vmName
                }
                vmSize = @{
                    value = $VMObjectHash.vmSize
                }
                numberOfInstances = @{
                    value = [int]$VMObjectHash.numberOfInstances
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
                adminPassword = @{ 
                    value = $VMObjectHash.adminPassword
                }
                vmDiagnosticStor = @{
                    value = $VMObjectHash.vmDiagnosticStor
                }
            }
        }
    $parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
    $parameterFile = $parameterFile.Replace("null", "")
    $parameterFile | Out-File -Encoding utf8 "$deployPath\$vmParamFileName"
    
    $azCommand = "az group deployment create -g " + $RGName + " --template-file $vmARMTemplate --parameters " + " @$deployPath\$vmParamFileName"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath\az-vm-create-cmd.bat"
}

###########################################
