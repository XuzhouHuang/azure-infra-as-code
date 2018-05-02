Add-AzureRmAccount -Environment AzureChinaCloud

Set-AzureRmContext c4013028-2728-46b8-acf1-e397840c4344

$ARMTemplateFile = "C:\kangxh\Infraascode\ServiceFabric\azuredeploy.json"
$ARMParamFile = "C:\kangxh\Test\arm-sf-param.json"

New-AzureRmResourceGroup -name $RG -location $Location
test-AzureRmResourceGroupDeployment -ResourceGroupName $RG -TemplateFile $ARMTemplateFile -TemplateParameterFile $ARMParamFile

New-AzureRmResourceGroupDeployment -Mode Incremental -Name infraascodetest -ResourceGroupName infra-as-code-sf -TemplateFile $ARMTemplateFile -TemplateParameterFile $ARMParamFile

