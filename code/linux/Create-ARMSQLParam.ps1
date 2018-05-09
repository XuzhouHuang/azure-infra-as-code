$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"
$sqlSheet = Import-Excel -Path $excelSheet -WorksheetName SQL -DataOnly

$envSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly
$subscriptionId = $envSheet[0].SubscriptionID

#$sqlTemplate = "$deployPath\sql-server-db.json"
$sqlTemplate = "C:\kangxh\VisualStudio\infra-as-code\SQL\sql-server-db.json"

"### create Azure SQL Resource command " | Out-File -Encoding utf8 "$deployPath/az-sql-create-cmd.bat"
foreach ($databaseinstance in $sqlSheet) {

    # read input parameter
    $resourceGroupName = $databaseinstance.'resource group';
    $resourceGroupLocation = $databaseinstance.'location'
    $Location =  $databaseinstance.'location';
    $serverName =  $databaseinstance.'server name';
    $SKU = $databaseinstance.'sku';
    $Tier = $databaseinstance.'tier';
    $username = $databaseinstance.'user name';

    $keyvaultRG = $databaseinstance.keyvaultRG;
    $keyvault = $databaseinstance.keyvault;
    $Secret = $databaseinstance.Secret;

    $databasename = $databaseinstance.'Database';
    $collation = $databaseinstance.'Collation'
    $encryption = $databaseinstance.'Encryption'
    
    $userPassword = @{ reference = @{keyVault = @{id = "/subscriptions/$subscriptionId/resourceGroups/$keyvaultRG/providers/Microsoft.KeyVault/vaults/$keyvault"}; secretName = $Secret} }
    $userPassword | ConvertTo-Json -Depth 10
    $parameterFile = @{
        contentVersion = "1.0.0.0";
        parameters = @{
                    serverName = @{
                      value = $serverName
                    }
                    location = @{
                        value = $location
                    }
                    skuName = @{
                        value = $SKU
                    }
                    tier = @{
                        value = $tier
                    }
                    username = @{
                        value = $username
                    }
                    userPassword = $userPassword
                    databasename = @{
                        value = $databasename
                    }
                    collation = @{
                        value = $collation
                    }
                    Encryption = @{
                        value = $Encryption
                    }
            }
}

    #create arm template file for each SQL database instance
    $sqlParamFileName = "$deployPath\arm-sql-$databasename-Param.json"
    
    $parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
    $parameterFile | Out-File -Encoding utf8 $sqlParamFileName 

    # build az command batch to create resource
    $azCommand = "az group deployment create -g " + $resourceGroupName + " --template-file $sqlTemplate --parameters " + " @$sqlParamFileName"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-sql-create-cmd.bat"
}
