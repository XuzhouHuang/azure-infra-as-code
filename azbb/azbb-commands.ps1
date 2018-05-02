az cloud list --output table                                                # list all the cloud option
az cloud set -n AzureChinaCloud                                                # set china cloud as the login cloud


az account list --output table                                              # list all the account can be managed
az account set -s c4013028-2728-46b8-acf1-e397840c4344                         # set account to manage


azbb -c AzureChinaCloud -s c4013028-2728-46b8-acf1-e397840c4344 -l ChinaNorth -g infra-as-code -p C:\kangxh\azbb\Test\azbb-vnet-param.json --deploy