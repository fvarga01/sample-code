# Demonstrates how to view/update a self-hosted integration runtime (SHIR) and SHIR node programmatically

$subscriptionName = ""
$adfName = ''
$rgName = ''
$SHIR_Name = ''
$SHIR_Node1Name = ''


#################################################################################################
# METHOD1: via Azure (Az) PowerShell (newer)
# Pre-req1: Uninstall AzureRm if you wish to use the latest Az module 
# Warning: You'll have to migrate azureRm scripts to Az
# Uninstall via Windows installer if you installed it that way instead of PowerShell Get
# https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-3.7.0

# Pre-req2:Install the latest Az module (azure PowerShell)
# https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-3.7.0
# If Powershell get method fails, then you need to Install offline:
#   https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.7.0#install-offline
#################################################################################################
#Verify Az Module is installed and that AzureRm is not installed
Get-InstalledModule -Name AzureRm -AllVersions | select Name,Version
Get-InstalledModule -Name Az -AllVersions | select Name,Version

#Connect to your Azure subscription
Connect-AzAccount -Subscription $subscriptionName
#verify your subscription context
get-azcontext

#list data factories
Get-azdatafactoryV2 -ResourceGroupName $rgName | select DataFactoryName, ResourceGroupName, Location, ProvisioningState

#View SHIR details
#  https://docs.microsoft.com/en-us/powershell/module/az.datafactory/get-azdatafactoryv2integrationruntime?view=azps-3.7.0
get-AzDataFactoryV2IntegrationRuntime  -ResourceGroupName $rgName `
    -DataFactoryName $adfName  -Name $SHIR_Name -Status
#Change SHIR Description
set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $rgName `
    -DataFactoryName $adfName -Name $SHIR_Name -Description "test description 3"
#View Changes
get-AzDataFactoryV2IntegrationRuntime  -ResourceGroupName $rgName `
    -DataFactoryName $adfName  -Name $SHIR_Name -Status | select Name, Description

#View SHIR Node details
#  https://docs.microsoft.com/en-us/powershell/module/Az.DataFactory/Get-AzDataFactoryV2IntegrationRuntimeNode?view=azps-3.7.0
Get-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name 
#Change SHIR Node's ConcurrentJobsLimit
Update-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name -ConcurrentJobsLimit 15
#View Changes
Get-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name | select ConcurrentJobsLimit, MaxConcurrentJobs

#################################################################################################
# METHOD2: via Azure RM PowerShell (older)
#################################################################################################

$subscriptionguid = 'enter-subscription-guid-here'
Connect-AzureRmAccount -Subscription $subscriptionguid

#View SHIR details
get-AzureRmDataFactoryV2IntegrationRuntime -ResourceGroupName $rgName `
    -DataFactoryName $adfName  -Name $SHIR_Name -Status -Verbose
#Change SHIR Description
Set-AzureRmDataFactoryV2IntegrationRuntime -ResourceGroupName $rgName `
    -DataFactoryName $adfName -Name $SHIR_Name -Description "test description 2"
#View Changes
get-AzureRmDataFactoryV2IntegrationRuntime -ResourceGroupName $rgName `
    -DataFactoryName $adfName  -Name $SHIR_Name -Status | select Description

#View SHIR Node details
Get-AzureRmDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name
#Change SHIR Node's ConcurrentJobsLimit
Update-AzureRmDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name -ConcurrentJobsLimit 14
#View Changes
Get-AzureRmDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName `
    -DataFactoryName $adfName -IntegrationRuntimeName  $SHIR_Name -Name $SHIR_Node1Name | select ConcurrentJobsLimit, MaxConcurrentJobs