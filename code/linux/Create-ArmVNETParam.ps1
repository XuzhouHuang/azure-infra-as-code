Import-Module "./Module.psm1"

$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"
$vnetSheet = Import-Excel -Path $excelSheet -WorksheetName vNet -DataOnly 

$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly 
$subscriptionId = $environmentSheet[1].SubscriptionID

#build vNet array
$vnetArray = @()
for ($i=0; $i -lt $vnetSheet.Count; $i++)
{
    if ($vnetSheet[$i].Properties -eq "resourceGroupName") { # find vnet table header
        [array]$dnsArray = @(); if ($vnetSheet[$i+3].value){ [array]$dnsArray = $vnetSheet[$i+3].value.Replace(" ","").Split(",")}
        [array]$ipArray = @(); if ($vnetSheet[$i+4].value){ [array]$ipArray = $vnetSheet[$i+4].value.Replace(" ","").Split(",")}
        $vnetArray += @{resourceGroupName = $vnetSheet[$i].value; location = $vnetSheet[$i+1].value; name = $vnetSheet[$i+2].value; dnsServers=$dnsArray; addressPrefixes = $ipArray}
    }
}

# build subnet array
$subnets = @{}
for ($i=0; $i -le $vnetSheet.Count; $i++)
{
    if (($vnetSheet[$i].C -eq "subnets") ) { 
        Continue  # table header, do nothing
    }
    if (($vnetSheet[$i].C -ne $null) -and ($vnetSheet[$i].D -ne "name") ) { # build the subnet array

        if ($subnets[$vnetSheet[$i].C].count -eq 0){
            $subnets[$vnetSheet[$i].C]=@() 
        } 
        $subnet = [pscustomobject]@{name = $vnetSheet[$i].D; addressPrefix = $vnetSheet[$i].E}
        $subnets[$vnetSheet[$i].C] += @($subnet)
    }
}

# Now, create the building block structure. for every vnet, we will create one Azbb Param file to make it flexible. 

"##### command to create azure network" | Out-File -Encoding utf8 "$deployPath/az-vnet-create-cmd.bat"
foreach ($vnet in $vnetArray){
    # 1. build Settings block for AZBB
    $settingsBLOCK = @()
    $settingsBLOCK += @{name = $vnet.name; addressPrefixes = $vnet.addressPrefixes; subnets = $subnets[$vnet.name]}

    # 2. build values block for AZBB, as we onlyl create one type in one script. this is an array with one item
    $valueBlock = @()
    $valueBlock += @{type = "VirtualNetwork"; settings = $settingsBLOCK}

    # 3. build Building block for AZBB
    $buildingBlocks = @()
    $buildingBlocks = @{value = $valueBlock}

    # 4. build Parameters
    $parameters = @{buildingBlocks=$buildingBlocks}

    # 5. building finale azbb parameter file
    $azbbParam = @{"contentVersion" = "1.0.0.0"; parameters = $parameters} | ConvertTo-Json -Depth 10
    
    #Now, export the generated Parameter files and generate the az command

    $azbbParamFileName = "arm-vnet-" + $vnet.name + "-Param.json"
    $azbbParam | Out-File -Encoding utf8 "$deployPath/$azbbParamFileName"

    $azCommand = "azbb -c AzureChinaCloud -s " + $subscriptionId + " -l " + $vnet.location + " -g " + $vnet.resourceGroupName  + " -p $deployPath/$azbbParamFileName --deploy"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-vnet-create-cmd.bat"
}

###################################################################################

$azbbvnetSample = '{
    "$schema": "https://raw.githubusercontent.com/mspnp/template-building-blocks/master/schemas/buildingBlocks.json",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "buildingBlocks": {
            "value": [
                {
                    "type": "VirtualNetwork",
                    "settings": [
                        {
                            "name": "msft-multiple-vnet",
                            "addressPrefixes": [
                                "10.0.0.0/16",
                                "11.0.0.0/16"
                            ],
                            "subnets": [
                                {
                                    "name": "firewall",
                                    "addressPrefix": "10.0.1.0/24"
                                },
                                {
                                    "name": "ad",
                                    "addressPrefix": "10.0.2.0/24"
                                },
                                {
                                    "name": "mgmt",
                                    "addressPrefix": "11.0.1.0/24"
                                },                                
                                {
                                    "name": "GatewaySubnet",
                                    "addressPrefix": "11.0.0.0/27"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    }
}'
