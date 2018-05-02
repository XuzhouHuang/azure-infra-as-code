# the script take 3 parameters: 
# 1. a deployment folder
# 2. the PowerShell modules file which contains the a module list to import. will copy this file to deployment folder as Module.psm1
# 3. the excel sheet file. we will copy this file to the deployment folder and rename it as AzureEnv.xlsx

 param (
    [Parameter()][string] $DeployFolder = "C:\kangxh\Infra-as-code\deployment",
    [Parameter()][string] $PSModule = "C:\kangxh\powershell\allenk-Module-Json.psm1",
    [Parameter()][string] $AzureFile = "C:\kangxh\Infra-as-code\deployment\poc-daimler.xlsx"
 )

 if ([System.Environment]::OSversion.Platform -match "Win") {$P="\"} else {$P="/"}

# create the deployment folder. the folder should be empty as we create the folder with datetime.
$targetFolder = get-date -Format yyyyMMddHHmm
New-Item -ItemType Directory -Force -Path "$DeployFolder$P$targetFolder"
cd "$DeployFolder$P$targetFolder"

# copy PSModule and AzureFile to the deployment folder
$moduleFile = ".$P"+"Module.psm1"
$excelSheet = ".$P"+"AzureEnv.xlsx"

Copy-Item -Path $PSModule -Destination $moduleFile
Copy-Item -Path $AzureFile -Destination $excelSheet

# read configuration data
Import-Module $moduleFile
$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly

$batchFile = ".$P"+"az-env-create-cmd.bat"

if ([System.Environment]::OSversion.Platform -match "Win") {
    "cd $DeployFolder$P$targetFolder" | Out-File -Encoding utf8 -Append $batchFile
    "az cloud list --output table" | Out-File -Encoding utf8 -Append $batchFile
    "az cloud set -n " + $environmentSheet[0].Cloud | Out-File -Encoding utf8 -Append $batchFile
    "az login --service-principal -u " + $environmentSheet[0].ApplicationID + " -p " + $environmentSheet[0].Certification + " --tenant " + $environmentSheet[0].TenantID  | Out-File -Encoding utf8 -Append $batchFile
    "az account list --output table" | Out-File -Encoding utf8 -Append $batchFile
    "az account set -s" + $environmentSheet[0].SubscriptionID | Out-File -Encoding utf8 -Append $batchFile
} else {
    "cd $DeployFolder$P$targetFolder"
    "az cloud list --output table" | Out-File -Encoding utf8 -Append $batchFile
    "az cloud set -n " + $environmentSheet[1].Cloud | Out-File -Encoding utf8 -Append $batchFile
    "az login --service-principal -u " + $environmentSheet[1].ApplicationID + " -p " + $environmentSheet[1].Certification + " --tenant " + $environmentSheet[1].TenantID  | Out-File -Encoding utf8 -Append $batchFile
    "az account list --output table" | Out-File -Encoding utf8 -Append $batchFile
    "az account set -s" + $environmentSheet[1].SubscriptionID | Out-File -Encoding utf8 -Append $batchFile
}

