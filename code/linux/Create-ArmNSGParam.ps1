Import-Module "./Module.psm1"

# Service Fabric is not available in AzBB. We use use our own ARM Template to Generate a Parameter Json. 
$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"
$nsgSheet = Import-Excel -Path $excelSheet -WorksheetName NSG -DataOnly 
$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly 

# build NSG Array
$nsgArray = @()
for ($i=0; $i -lt $nsgSheet.Count; $i++)
{
    if ($nsgSheet[$i].Properties -eq "resourceGroupName") { # find nsg table header
        $nsgArray += @{resourceGroupName = $nsgSheet[$i].B; location = $nsgSheet[$i+1].B; name = $nsgSheet[$i+2].B}
    }
}

# build nsg rules array
$nsgRules = @{}
for ($i=0; $i -le $nsgSheet.Count; $i++)
{
    if (($nsgSheet[$i].C -eq "securityRules") ) { 
        Continue  # table header, do nothing
    }
    if (($nsgSheet[$i].C -ne $null) -and ($nsgSheet[$i].D -ne "name") ) { # build the rule array

        if ($nsgRules[$nsgSheet[$i].C].count -eq 0){
            $nsgRules[$nsgSheet[$i].C]=@() 
        } 
        $nsgRule = [pscustomobject]@{name = $nsgSheet[$i].D; sourceAddressPrefix = $nsgSheet[$i].E; sourcePortRange = $nsgSheet[$i].F; protocol = $nsgSheet[$i].G; destinationAddressPrefix = $nsgSheet[$i].H; destinationPortRange = $nsgSheet[$i].I; access = $nsgSheet[$i].J; priority = $nsgSheet[$i].K; direction = $nsgSheet[$i].L}
        $nsgRules[$nsgSheet[$i].C] += @($nsgRule)
    }
}

# build nsg virtual networks array nsgVNETs[nsgName]
$nsgVNETs = @{}
for ($i=0; $i -le $nsgSheet.Count; $i++)
{
    if ($nsgSheet[$i].M -eq "virtualNetworks") { 
        Continue # table header, do nothing
    }

    if (($nsgSheet[$i].M -ne $null) -and ($nsgSheet[$i].N -ne "resourceGroupName") ) { # build the virtual networks array
        if ($nsgVNETs[$nsgSheet[$i].M].count -eq 0){
            $nsgVNETs[$nsgSheet[$i].M]=@() # intialize the networks for this nsg
        } 

        # get the subnet list and create an array
        [array]$subnets = $nsgSheet[$i].P.Replace(" ","").Split(",")

        # Build the vNetwork array
        $nsgVNETs[$nsgSheet[$i].M] += [pscustomobject]@{ resourceGroupName = $nsgSheet[$i].N; name = $nsgSheet[$i].O; subnets = $subnets}
    }
}

# output data to param file and build the command line
"##### azure command to create NSGs" | Out-File -Encoding utf8 -Append "$deployPath/az-nsg-create-cmd.bat"
foreach ($nsg in $nsgArray)
{


    # 1. build Settings block for AZBB
    $settingsBLOCK = @()
    $settingsBLOCK += @{name = $nsg.name; securityRules = $nsgRules[$nsg.name]; virtualNetworks = $nsgVNETs[$nsg.name]}

    # 2. build values block for AZBB, as we onlyl create one type in one script. this is an array with one item
    $valueBlock = @()
    $valueBlock += @{type = "NetworkSecurityGroup"; settings = $settingsBLOCK}

    # 3. build Building block for AZBB
    $buildingBlocks = @()
    $buildingBlocks = @{value = $valueBlock}

    # 4. build Parameters
    $parameters = @{buildingBlocks=$buildingBlocks}

    # 5. building finale azbb parameter file
    $azbbParam = @{"contentVersion" = "1.0.0.0"; parameters = $parameters} | ConvertTo-Json -Depth 10

    #Now, export the generated Parameter files and generate the az command
    $azbbParamFileName = "arm-nsg-" + $nsg.name + "-Param.json"
    $azbbParam | Out-File -Encoding utf8 "$deployPath/$azbbParamFileName"

    $azCommand = "azbb -c AzureChinaCloud -s " + $subscriptionId + " -l " + $nsg.location + " -g " + $nsg.resourceGroupName  + " -p $deployPath/$azbbParamFileName --deploy"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-nsg-create-cmd.bat"
}


#Sample of NSG Parameters 
$paramFileSample = '{
        "contentVersion": "1.0.0.0",
        "parameters": {
            "buildingBlocks": {
                "value": [
                    {
                        "type": "NetworkSecurityGroup",
                        "settings": [
                            {
                                "name": "mynsg",
                                "securityRules": [
                                    {
                                      "name": "rule1",
                                      "protocol": "TCP",
                                      "sourcePortRange": "*",
                                      "destinationPortRange": 3389,
                                      "sourceAddressPrefix": "Internet",
                                      "destinationAddressPrefix": "*",
                                      "access": "Deny",
                                      "priority": 101,
                                      "direction": "Inbound"
                                    },
                                    {
                                      "name": "rule2",
                                      "protocol": "*",
                                      "sourcePortRange": "*",
                                      "destinationPortRange": "*",
                                      "sourceAddressPrefix": "*",
                                      "destinationAddressPrefix": "Internet",
                                      "access": "Deny",
                                      "priority": 200,
                                      "direction": "Outbound"
                                    }
                                ],
                                "virtualNetworks":[
                                    {
                                        "name":  "vnet1",
                                        "resourceGroupName":  "rg1",
                                        "subnet":  ["subnet1","subnet2"]
                                    },
                                    {
                                        "name":  "vnet2",
                                        "resourceGroupName":  "rg2",
                                        "subnet":  ["subnet1","subnet2"]
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        }
    }'




