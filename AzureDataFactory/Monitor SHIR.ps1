# Pre-req1: Uninstall AzureRm. We will instead use the latest Az cmodule 
# Warning: You'll have to migrate azureRm scripts to Az)
# Uninstall via Windows installer if you installed it that way instead of PowerShell Ge
# https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps?view=azps-3.7.0

# Pre-req2:Install the latest Az module (azure PowerShell)
# https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-3.7.0
# If Powershell get method fails, then you need to Install offline:
#   https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-3.7.0#install-offline


#Verify Az Module is installed and that AzureRm is not installed
Get-InstalledModule -Name AzureRm -AllVersions | select Name,Version
Get-InstalledModule -Name Az -AllVersions | select Name,Version


$subscriptionName = ""
$rgName = ""
$adfName = ""
$SHIR_Name  = ""
$SHIR_Node1Name = ""
$SHIR_Node2Name = ""

#Logon to Azure + Verify subscription context
Connect-AzAccount -Subscription $subscriptionName
get-azcontext

#list data factories
Get-azdatafactoryV2 $rgName

# Monitor SHIR, see example 5:
#  https://docs.microsoft.com/en-us/powershell/module/az.datafactory/get-azdatafactoryv2integrationruntime?view=azps-3.7.0
Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $rgName -DataFactoryName $adfName -Name $SHIR_Name -Status


# Monitor SHIR Node see example1: 
#  https://docs.microsoft.com/en-us/powershell/module/Az.DataFactory/Get-AzDataFactoryV2IntegrationRuntimeNode?view=azps-3.7.0
Get-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName -DataFactoryName $adfName  -IntegrationRuntimeName $SHIR_Name -Name $SHIR_Node1Name
Get-AzDataFactoryV2IntegrationRuntimeNode -ResourceGroupName $rgName -DataFactoryName $adfName  -IntegrationRuntimeName $SHIR_Name -Name $SHIR_Node2Name

#ping SHIR nodes
Test-NetConnection -ComputerName $SHIR_Node1Name #-Port 1433
Test-NetConnection -ComputerName $SHIR_Node2Name #-Port 1433


#check dns cache
Get-DnsClientCache -Name $SHIR_Node1Name
Get-DnsClientCache -Name $SHIR_Node2Name

#clear local dns cache
#Clear-DnsClientCache