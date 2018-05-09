Import-Module "./Module.psm1"

$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"
$kvSheet = Import-Excel -Path $excelSheet -WorksheetName KeyVault -DataOnly 

$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly 
$subscriptionId = $environmentSheet[1].SubscriptionID
$tenantID = $environmentSheet[1].TenantID

$kvARMTemplate = "../../arm/KeyVault/KeyVault.json"
Copy-Item -Path $kvARMTemplate -Destination "./KeyVault.json"
$kvARMTemplate = "$deployPath/KeyVault.json"

$kvSecretsARMTemplate = "../../arm/KeyVault/KeyVault.json"
Copy-Item -Path $kvSecretsARMTemplate -Destination "./KeyVaultSecrets.json"
$kvSecretsARMTemplate = "$deployPath/KeyVaultSecrets.json"

# build KeyVault Array
$kvArray = @()
for ($i=0; $i -lt $kvSheet.Count; $i++)
{
    if ($kvSheet[$i].Properties -eq "resourceGroupName") { # find key vault table header
        $kvArray += @{resourceGroupName = $kvSheet[$i].B; location = $kvSheet[$i+1].B; tenantId = $tenantID; name = $kvSheet[$i+2].B; enabledForDeployment = $kvSheet[$i+3].B; enabledForTemplateDeployment = $kvSheet[$i+4].B; enableVaultForVolumeEncryption = $kvSheet[$i+5].B;
        }
    }
}

# build KeyVault Access Policy array
$kvAccessPolicyArray = @{}
for ($i=0; $i -le $kvSheet.Count; $i++)
{
    if (($kvSheet[$i].C -eq "accessPolicies") ) { 
        Continue  # table header, do nothing
    }
    if (($kvSheet[$i].C -ne $null) -and ($kvSheet[$i].D -ne "objectName") ) { # build the AccessPolicy array

        if ($kvAccessPolicyArray[$kvSheet[$i].C].count -eq 0){
            $kvAccessPolicyArray[$kvSheet[$i].C]=@() 
        } 

        $permissionKeys = @($kvSheet[$i].F.Replace(" ","").Split(","))
        $permissionSecrets = @($kvSheet[$i].G.Replace(" ","").Split(","))
        $permissionCerts = @($kvSheet[$i].H.Replace(" ","").Split(","))

        $Permissions = @{keys = $permissionKeys; secrets = $permissionSecrets; certificates = $permissionCerts}

        $kvAccessPolicy = [pscustomobject]@{tenantId = $tenantID; objectId = $kvSheet[$i].E; permissions = $Permissions}
        $kvAccessPolicyArray[$kvSheet[$i].C] += @($kvAccessPolicy)
    }
}

# build KeyVault secrets array kvSecret[keyvaultname]
$secretsName = @{}; $secretsValue = @{}
for ($i=0; $i -le $kvSheet.Count; $i++)
{
    if ($kvSheet[$i].I -eq "KeyVaultName") { 
        Continue # table header, do nothing
    }

    if (($kvSheet[$i].I -ne $null) -and ($kvSheet[$i].J -ne "secretsName") ) { # build the secrets arrays
        if ($secretsName[$kvSheet[$i].I].count -eq 0){
            $secretsName[$kvSheet[$i].I] = @() 
            $secretsValue[$kvSheet[$i].I] = @() 
        } 

        if ($kvSheet[$i].K -eq "YES") { # only when new value required, we will create secret, otherwise, skip that line
            # Create a secret resource item
            $kvName = $kvSheet[$i].I
            
            $secretName = $kvSheet[$i].J
            $secretValue = New-StrongPassword
            # Build the secrets array
            $secretsName[$kvName] += @($secretName)
            $secretsValue[$kvName] += @($secretValue)
        }
    }
}

"### create Azure KeyVault command " | Out-File -Encoding utf8 "$deployPath/az-kv-create-cmd.bat"
foreach ($keyvault in $kvArray){
    # build Key Vault Param file
    $kvParamFile = @{
        contentVersion = "1.0.0.0";
        parameters = @{
            keyVaultName = @{
                value = $keyvault.name
            }
            tenantId = @{
                value = $keyvault.tenantId
            }
            accessPolicies = @{
                value = $kvAccessPolicyArray[$keyvault.name] 
            }
            enabledForDeployment = @{
                value = $keyvault.enabledForDeployment
            }
            enabledForTemplateDeployment = @{
                value = $keyvault.enabledForTemplateDeployment
            }
            enableVaultForVolumeEncryption = @{
                value = $keyvault.enableVaultForVolumeEncryption
            }
        }
    }
    $kvParamFileName = "arm-kv-" + $keyvault.name + "-Param.json"
    $kvParamFile = ConvertTo-Json -InputObject $kvParamFile -Depth 10
    $kvParamFile = $kvParamFile.Replace("null", "")
    $kvParamFile | Out-File -Encoding utf8 "$deployPath/$kvParamFileName"
    $azCommand = "az group deployment create -g " + $keyvault.resourceGroupName + " --template-file $kvARMTemplate --parameters " + " @$deployPath/$kvParamFileName"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-kv-create-cmd.bat"

    $secretsParamFile = @{
        contentVersion = "1.0.0.0";
        parameters = @{
            keyVaultName = @{
                value = $keyvault.name
            }
            numberOfSecrets = @{
                value = $secretsName[$keyvault.name].Count
            }
            secretsName = @{
                value = $secretsName[$keyvault.name]
            }
            secretsValue = @{
                value = $secretsValue[$keyvault.name]
            }
        }
    }
    # Call secrets template when needed
    if ($secretsName[$keyvault.name].Count -gt 0) {
        $secretsParamFileName = "arm-kv-" + $keyvault.name + "-Secrets-Param.json"
        $secretsParamFile = ConvertTo-Json -InputObject $secretsParamFile -Depth 10
        $secretsParamFile = $secretsParamFile.Replace("null", "")
        $secretsParamFile | Out-File "$deployPath/$secretsParamFileName"
        $azCommand = "az group deployment create -g " + $keyvault.resourceGroupName + " --template-file $kvSecretsARMTemplate --parameters " + " @$deployPath/$secretsParamFileName"
        $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-kv-create-cmd.bat"
        "# rm $deployPath/$secretsParamFileName -f" | Out-File -Encoding utf8 -Append "$deployPath/az-kv-create-cmd.bat"
    }
}
