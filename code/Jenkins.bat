cd C:\kangxh\Test

call az cloud list --output table 
call az cloud set -n AzureChinaCloud 
call az login -u allenk@mcpod.partner.onmschina.cn -p Dou123dou
call az account list --output table
call az account set -s c4013028-2728-46b8-acf1-e397840c4344

call azbb -c AzureChinaCloud -s c4013028-2728-46b8-acf1-e397840c4344 -l ChinaNorth -g infra-as-code -p C:\kangxh\Test\azbb-vnet-param.json 

call az cloud list --output table 