cd "C:\kangxh\Infra-as-code\deployment\201804251425"

Import-Module "C:\kangxh\powershell\allenk-Module-Json.psm1"

# Service Fabric is not available in AzBB. We use use our own ARM Template to Generate a Parameter Json. 
$deployPath = Convert-Path .
$codePath = "C:\kangxh\Infra-as-code\code\"

$excelSheet = $deployPath + "\poc-daimler.xlsx"
$vmARMTemplate = "C:\kangxh\Projects\MoonCake\Customers\Daimler\ROSS2018031201573673\DaimlerARM\VMGroup\azuredeploy.json"

$vmSheet = Import-Excel -Path $excelSheet -WorksheetName VM

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

    if ($VMObjectHash.vmName) {
        $RGName = $VMObjectHash.ResourceGroup; $VMObjectHash.Remove('ResourceGroup')
        $Location = $VMObjectHash.'Location'; $VMObjectHash.Remove('Location')
        $vmParamFileName = "vm-" + $VMObjectHash.vmName + "-Param.json"

        $VMObjectHash | ConvertTo-Json | Out-File -Encoding utf8 "$deployPath\$vmParamFileName"
        
        $azCommand = "az group deployment create -g " + $RGName + " --template-file $vmARMTemplate --parameters " + "@$deployPath\" + $vmParamFileName
        $azCommand | Out-File -Encoding utf8 -Append "$deployPath\az-vm-create-cmd.bat"
    }
}


