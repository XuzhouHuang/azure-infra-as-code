Import-Module "C:\kangxh\powershell\allenk-Module-Json.psm1"

cd "C:\kangxh\Infra-as-code\deployment\201804251425"

$deployPath = Convert-Path .
$codePath = "C:\kangxh\Infra-as-code\code\"
$excelSheet = $deployPath + "\poc-daimler.xlsx"

$vnetSheet = Import-Excel -Path $excelSheet -WorksheetName vnet

# Parse the main properties for vNet 
$RG = $vnetSheet[0].C; $Location = $vnetSheet[0].D

$BuildingBlocks_value_settings_name                 = $vnetSheet[1].C
$BuildingBlocks_value_settings_addressPrefixes      = @($vnetSheet[1].D)
$BuildingBlocks_value_settings_dnsservers           = @($vnetSheet[2].C)

#Find key line ID in vnetSheet.
foreach ($dataline in $vnetSheet)
{
    if ($dataline.Properties -eq "Subnet Name") { $SubnameLineStarts = $vnetSheet.IndexOf($dataline)}
    if ($dataline.Properties -eq "Peering vNet Name") { $PeeringLineStarts = $vnetSheet.IndexOf($dataline)}
    if ($dataline.Properties -eq "NSG Name") { $NSGLineStarts = $vnetSheet.IndexOf($dataline)}
}

# build Subnet list.
$BuildingBlocks_value_settings_subnets = @()
$subnetObj = @{}
for ($i=$SubnameLineStarts + 1; $i -lt $PeeringLineStarts; $i++)
{
    if ($vnetSheet[$i].Properties -ne $null)
    {
        $subnetObj = @{ name = $vnetSheet[$i].Properties ; addressPrefix = $vnetSheet[$i].C}
        $BuildingBlocks_value_settings_subnets += $subnetObj
    }
}

# building the azbb parameter file for vNet
$parameterFile = @{
    contentVersion = '1.0.0.0';
    parameters = @{
        buildingBlocks = @{
            value = @(
                @{
                    type = 'VirtualNetwork';
                    settings = @(
                        @{
                            name = $BuildingBlocks_value_settings_name;                    
                            dnsServers = @($BuildingBlocks_value_settings_dnsservers);
                            addressPrefixes = @($BuildingBlocks_value_settings_addressPrefixes);
                            subnets = @($BuildingBlocks_value_settings_subnets)
                        }
                    )
                }
            )
        }
    }
} 

$parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
$parameterFile = $parameterFile.Replace("null", "")
$parameterFile | Out-File -Encoding utf8 "$deployPath\vnet-$BuildingBlocks_value_settings_name-param.json"

$azCommand = "azbb -c AzureChinaCloud -s c4013028-2728-46b8-acf1-e397840c4344 -g " + $RG + " -l " + $Location + "  -p " + "$deployPath\vnet-$BuildingBlocks_value_settings_name-param.json"
$azCommand | Out-File -Encoding utf8 -Append "$deployPath\az-vnet-create-cmd.bat"

