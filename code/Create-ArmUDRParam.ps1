cd C:\kangxh\Infra-as-code\deployment\201804280801

Import-Module ".\Module.psm1"

# Service Fabric is not available in AzBB. We use use our own ARM Template to Generate a Parameter Json. 
$deployPath = Convert-Path .
$excelSheet = $deployPath + "\AzureEnv.xlsx"
$udrSheet = Import-Excel -Path $excelSheet -WorksheetName UDR -DataOnly 
$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly 

if ([System.Environment]::OSversion.Platform -match "Win") {
    $subscriptionId = $environmentSheet[0].SubscriptionID
} else {
    $subscriptionId = $environmentSheet[1].SubscriptionID
}

# build UDR Array
$udrArray = @()
for ($i=0; $i -lt $udrSheet.Count; $i++)
{
    if ($udrSheet[$i].Properties -eq "resourceGroupName") { # find udr table header
        $udrArray += @{resourceGroupName = $udrSheet[$i].B; location = $udrSheet[$i+1].B; name = $udrSheet[$i+2].B}
    }
}

# build udr rules array
$udrRules = @{}
for ($i=0; $i -le $udrSheet.Count; $i++)
{
    if (($udrSheet[$i].C -eq "rules") ) { 
        Continue  # table header, do nothing
    }
    if (($udrSheet[$i].C -ne $null) -and ($udrSheet[$i].D -ne "name") ) { # build the rule array

        if ($udrRules[$udrSheet[$i].C].count -eq 0){
            $udrRules[$udrSheet[$i].C]=@() 
        } 
        $udrRule = [pscustomobject]@{name = $udrSheet[$i].D; addressPrefix = $udrSheet[$i].E; nextHop = $udrSheet[$i].F; nextHopIP = $udrSheet[$i].G}
        $udrRules[$udrSheet[$i].C] += @($udrRule)
    }
}


# build udr virtual networks array udrVNETs[udrName]
$udrVNETs = @{}
for ($i=0; $i -le $udrSheet.Count; $i++)
{
    if ($udrSheet[$i].I -eq "virtualNetworks") { 
        Continue # table header, do nothing
    }

    if (($udrSheet[$i].I -ne $null) -and ($udrSheet[$i].J -ne "resourceGroupName") ) { # build the virtual networks array
        if ($udrVNETs[$udrSheet[$i].I].count -eq 0){
            $udrVNETs[$udrSheet[$i].I]=@() # intialize the networks for this udr
        } 

        # get the subnet list and create an array
        [array]$subnets = $udrSheet[$i].L.Replace(" ","").Split(",")

        # Build the vNetwork array
        $udrVNETs[$udrSheet[$i].I] += [pscustomobject]@{ resourceGroupName = $udrSheet[$i].J; name = $udrSheet[$i].K; subnets = $subnets}
    }
}

# output data to param file and build the command line
foreach ($udr in $udrArray)
{
    # 1. build Settings block for AZBB
    $settingsBLOCK = @()
    $settingsBLOCK += @{name = $udr.name; virtualNetworks = $udrVNETs[$udr.name]; routes = $udrRules[$udr.name]}

    # 2. build values block for AZBB, as we onlyl create one type in one script. this is an array with one item
    $valueBlock = @()
    $valueBlock += @{type = "RouteTable"; settings = $settingsBLOCK}

    # 3. build Building block for AZBB
    $buildingBlocks = @()
    $buildingBlocks = @{value = $valueBlock}

    # 4. build Parameters
    $parameters = @{buildingBlocks=$buildingBlocks}

    # 5. building finale azbb parameter file
    $azbbParam = @{"contentVersion" = "1.0.0.0"; parameters = $parameters} | ConvertTo-Json -Depth 10

    #Now, export the generated Parameter files and generate the az command
    $azbbParamFileName = "arm-udr-" + $udr.name + "-Param.json"
    $azbbParam | Out-File -Encoding utf8 "$deployPath\$azbbParamFileName"

    $azCommand = "azbb -c AzureChinaCloud -s " + $subscriptionId + " -l " + $udr.location + " -g " + $udr.resourceGroupName  + " -p $deployPath\$azbbParamFileName --deploy"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath\az-udr-create-cmd.bat"
}


####################################################################################

$paramFileSample = '{
    "$schema": "https://raw.githubusercontent.com/mspnp/template-building-blocks/master/schemas/buildingBlocks.json",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "buildingBlocks": {
            "value": [
                {
                    "type": "RouteTable",
                    "settings": [
                        {
                            "name": "msft-complete-rt",
                            "virtualNetworks": [
                                {
                                    "name": "msft-multiple-vnet",
                                    "subnets": [
                                        "firewall",
                                        "ad"
                                    ]
                                }
                            ],
                            "routes": [
                                {
                                    "name": "route1",
                                    "addressPrefix": "10.0.1.0/24",
                                    "nextHop": "VnetLocal"
                                },
                                {
                                    "name": "route2",
                                    "addressPrefix": "10.0.2.0/24",
                                    "nextHop": "192.168.1.1"
                                },
                                {
                                    "name": "route3",
                                    "addressPrefix": "10.0.3.0/24",
                                    "nextHop": "VirtualNetworkGateway"
                                }
                            ],
                            "tags": {
                                "department": "administration"
                            }
                        }
                    ]
                }
            ]
        }
    }
}'
