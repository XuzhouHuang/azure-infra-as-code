Import-Module ".\Module.psm1"

# Service Fabric is not available in AzBB. We use use our own ARM Template to Generate a Parameter Json. 
$deployPath = Convert-Path .

$excelSheet = $deployPath + "/AzureEnv.xlsx"
$rgSheet = Import-Excel -Path $excelSheet -WorksheetName RG -DataOnly 

"#### az command to create resource groups" | Out-File -Encoding utf8 $deployPath/az-rg-create-cmd.bat

for ($i = 0; $i -lt $rgSheet.Count; $i++) 
{
    $RGName = $rgSheet[$i].RGName
    $Location = $rgSheet[$i].Location
    
    $azStr = "az group create --name " + $RGName + " --location " + $Location
    $azStr | Out-File -Encoding utf8 -Append $deployPath/az-rg-create-cmd.bat
}

