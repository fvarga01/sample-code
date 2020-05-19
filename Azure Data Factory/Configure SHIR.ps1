# Demonstrates how to view and update an Azure Data Factory (ADF)
# self-hosted integration runtime (SHIR) and SHIR node programmatically

#################################################################################################
# This script uses the Azure (Az) PowerShell module (newer)

# If you do not have the latest Azure PowerShell Module installed, consider using the Azure cloud shell
# https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart-powershell#start-cloud-shell

# Pre-req1: Uninstall AzureRm if you wish to use the latest Az module 
# Warning: You'll have to migrate azureRm scripts to Az
# Uninstall via Windows installer if you installed it that way instead of PowerShell Get
# https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-3.7.0

# Pre-req2:Install the latest Az module (azure PowerShell)
# https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-3.7.0
# If Powershell get method fails, then you need to Install offline:
#   https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.7.0#install-offline
#################################################################################################

$subscriptionName = ''
$adfName = ''
$rgName = ''
$SHIR_Name = ''
$SHIR_Node1Name = ''
$newSHIRNodeConcurrencyLimit = 60
$newSHIRDescription =''

#Verify Az Module is installed and that AzureRm is not installed
Get-InstalledModule -Name AzureRm -AllVersions | Select-Object Name,Version
Get-InstalledModule -Name Az -AllVersions | Select-Object Name,Version

#Connect to your Azure subscription
Connect-AzAccount -Subscription $subscriptionName
#verify your subscription context
get-azcontext

#list data factories
Get-azdatafactoryV2 -ResourceGroupName $rgName |
     Select-Object DataFactoryName, ResourceGroupName, Location, ProvisioningState

#View SHIR details
#  https://docs.microsoft.com/en-us/powershell/module/az.datafactory/get-azdatafactoryv2integrationruntime?view=azps-3.7.0
get-AzDataFactoryV2IntegrationRuntime  -ResourceGroupName $rgName `
    -DataFactoryName $adfName  -Name $SHIR_Name -Status
#Change SHIR Description
set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $rgName `
    -DataFactoryName $adfName -Name $SHIR_Name -Description $newSHIRDescription
#View Changes
get-AzDataFactoryV2IntegrationRuntime  -ResourceGroupName $rgName `
    -DataFactoryName $adfName  -Name $SHIR_Name -Status |
    Select-Object Name, Description

#View SHIR Node details
#  https://docs.microsoft.com/en-us/powershell/module/Az.DataFactory/Get-AzDataFactoryV2IntegrationRuntimeNode?view=azps-3.7.0
Get-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name 
#Change SHIR Node's ConcurrentJobsLimit
Update-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name `
    -ConcurrentJobsLimit $newSHIRNodeConcurrencyLimit
#View Changes
Get-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name |
    Select-Object ConcurrentJobsLimit, MaxConcurrentJobs

#Get a list of all the ADF linked services and their respective integration runtimes
Get-AzDataFactoryV2LinkedService -ResourceGroupName $rgName -DataFactoryName $adfName |
     Select-Object Name -ExpandProperty Properties |
     Select-Object @{n="Linked Service Name";e={$_.Name}},
        @{n="Integration Runtime Name";e={if($_.ConnectVia) {$_.ConnectVia.ReferenceName} else {"<default>"}}} |
     Sort-Object -Property "Integration Runtime Name"
