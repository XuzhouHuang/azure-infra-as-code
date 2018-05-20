Import-Module "./Module.psm1"

$deployPath = Convert-Path .

$excelSheet = $deployPath + "/AzureEnv.xlsx"
$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly 
$sqlSheet = Import-Excel -Path $excelSheet -WorksheetName SQL -DataOnly
$subscriptionId = $environmentSheet[1].SubscriptionID

$sqlTemplate = "../../arm/SQL/sql-server-db.json"
Copy-Item -Path $sqlTemplate -Destination "./sql-server-db.json"
$sqlTemplate = "$deployPath/sql-server-db.json"

$secretTemplate = "../../arm/SQL/sql-db-connection-secret.json"
Copy-Item -Path $secretTemplate -Destination "./sql-db-connection-secret.json"
$secretTemplate = "$deployPath/sql-db-connection-secret.json"

"### create Azure SQL Resource command " | Out-File -Encoding utf8 "$deployPath/az-sql-create-cmd.bat"
foreach ($databaseinstance in $sqlSheet) {

    # read input parameter
    $resourceGroupName = $databaseinstance.'resource group';
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

    $parameterSecretFile = @{
        contentVersion = "1.0.0.0";
        parameters = @{
                    keyVaultName = @{
                        value = $keyvault
                    }
                    sqlServerName = @{
                        value = $serverName
                    }
                    sqlDatabaseName = @{
                        value = $databasename
                    }
                    sqlDatabaseAdmin = @{
                        value = $username
                    }
                    sqlDatabaseAdminPassword = $userPassword
            }
        }
    # Create SQL Connection String Secrets.

    #create arm template file for each SQL database instance
    $sqlParamFileName = "$deployPath/arm-sql-$serverName-$databasename-Param.json"
    
    $parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
    $parameterFile | Out-File -Encoding utf8 $sqlParamFileName 

    # build az command batch to create resource
    $azCommand = "az group deployment create -g " + $resourceGroupName + " --template-file $sqlTemplate --parameters " + " @$sqlParamFileName"
    $azCommand = "az group deployment create -g " + $keyvaultRG + " --template-file $secretTemplate --parameters " + " @$parameterSecretFile"
    
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-sql-create-cmd.bat"
}
