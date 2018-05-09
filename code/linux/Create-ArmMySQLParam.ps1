Import-Module "./Module.psm1"

$deployPath = Convert-Path .
$excelSheet = $deployPath + "/AzureEnv.xlsx"
$mysqlSheet = Import-Excel -Path $excelSheet -WorksheetName MySQL -DataOnly

$envSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly
$subscriptionId = $envSheet[0].SubscriptionID

$mysqlTemplate = "../../arm/SQL/mysql-server-db.json"
Copy-Item -Path $mysqlTemplate -Destination "./mysql-server-db.json"
$mysqlTemplate = "$deployPath/mysql-server-db.json"

"# create Azure mySQL command" | Out-File -Encoding utf8 "$deployPath/az-mysql-create-cmd.bat"
foreach ($mysqlinstance in $mysqlSheet) {

    # read input parameter
    $resourceGroupName = $mysqlinstance.'resource group';
    $resourceGroupLocation =  $mysqlinstance.'location';
    $serverName =  $mysqlinstance.'server name';
    $Location = $mysqlinstance.'location';
    $SKU = $mysqlinstance.'tier';
    $Version = $mysqlinstance.'version';
    $username = $mysqlinstance.'user name';
    $databasename = $mysqlinstance.'database';
    $charset = $mysqlinstance.'charset';
    $collation = $mysqlinstance.'collation'
    $addazuretoaccess = $mysqlinstance.'Allow Azure internal Access'

    $keyvaultRG = $databaseinstance.KeyVaultRG;
    $keyvault = $databaseinstance.KeyVault;
    $secret = $databaseinstance.Secret;
    $adminpassword = @{ reference = @{keyVault = @{id = "/subscriptions/$subscriptionId/resourceGroups/$keyvaultRG/providers/Microsoft.KeyVault/vaults/$keyvault"}; secretName = $secret} }

    $parameterFile = @{
        contentVersion = "1.0.0.0";
        parameters = @{
                    serverName = @{
                      value = $serverName
                    }
                    location = @{
                        value = $location
                    }
                    sku = @{
                        value = $sku.ToUpper()
                    }
                    version = @{
                        value = $version.ToString()
                    }
                    username = @{
                        value = $username
                    }
                    adminname = @{
                        value = $serverName+'%'+$username
                    }
                    adminpassword = $adminpassword
                    privilegeName = @{
                        value = $username
                    }
                    databasename = @{
                        value = $databasename
                    }
                    charset = @{
                        value = $charset
                    }
                    collation = @{
                        value = $collation
                    }
                    addazuretoaccess = @{
                        value = $addazuretoaccess
                    }
            }
    }

    #create arm template file for each mySQL instance 
    $mysqlParamFileName = "$deployPath/arm-mysql-$servername($databasename)-param.json"

    $parameterFile = ConvertTo-Json -InputObject $parameterFile -Depth 10
    $parameterFile | Out-File -Encoding utf8 $mysqlParamFileName 

    # build az command batch to create resource
    $azCommand = "az group deployment create -g " + $resourceGroupName + " --template-file $mysqlTemplate --parameters " + " @$mysqlParamFileName"
    $azCommand | Out-File -Encoding utf8 -Append "$deployPath/az-mysql-create-cmd.bat"
}
