cd C:\kangxh\Infra-as-code\deployment\201804280801
az cloud list --output table
az cloud set -n AzureChinaCloud
az login --service-principal -u 47a639b4-f614-4e56-a2bf-6979f64ce5cf -p C:\kangxh\AzureLabs\Certs\mc-allenk-automation-spn.pem --tenant 954ddad8-66d7-47a8-8f9f-1316152d9587
az account list --output table
az account set -sc4013028-2728-46b8-acf1-e397840c4344
