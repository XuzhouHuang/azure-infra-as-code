Import-Module "C:\Program Files (x86)\WindowsPowerShell\Modules\ImportExcel\4.0.11\ImportExcel.psm1"

# Service Fabric is not available in AzBB. We use use our own ARM Template to Generate a Parameter Json. 
cd C:\kangxh\Infra-as-code\Test
$vmSheet = Import-Excel -Path C:\kangxh\Infra-as-code\Test\poc-daimler.xlsx -WorksheetName VM

# Parse the main properties for vNet 
$RG = $vmSheet[0].C; $Location = $vmSheet[0].D

$BuildingBlocks_value_settings_name                 = $vmSheet[1].C
$BuildingBlocks_value_settings_addressPrefixes      = @($vmSheet[1].D)
$BuildingBlocks_value_settings_dnsservers           = @($vmSheet[2].C)

#Find key line ID in vmSheet.
foreach ($dataline in $vmSheet)
{
    if ($dataline.Properties -eq "Subnet Name") { $SubnameLineStarts = $vmSheet.IndexOf($dataline)}
    if ($dataline.Properties -eq "Peering vNet Name") { $PeeringLineStarts = $vmSheet.IndexOf($dataline)}
    if ($dataline.Properties -eq "NSG Name") { $NSGLineStarts = $vmSheet.IndexOf($dataline)}
}

# build Subnet list.
$BuildingBlocks_value_settings_subnets = @()
$subnetObj = @{}
for ($i=$SubnameLineStarts + 1; $i -lt $PeeringLineStarts; $i++)
{
    if ($vmSheet[$i].Properties -ne $null)
    {
        $subnetObj = @{ name = $vmSheet[$i].Properties ; addressPrefix = $vmSheet[$i].C}
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
$parameterFile | Out-File -Encoding utf8 /data/infra-as-code/userdata/azbb-vnet-param.json 

