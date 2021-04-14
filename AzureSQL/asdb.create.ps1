# Script Purpose: Create Azure SQL Databases via PowerShell
Read-Host "Hit Enter to continue running this script..."

#references:
# https://docs.microsoft.com/en-us/azure/sql-database/sql-database-powershell-samples?toc=%2fpowershell%2fmodule%2ftoc.json&view=azps-1.7.0
# https://docs.microsoft.com/en-us/azure/sql-database/scripts/sql-database-monitor-and-scale-database-powershell?toc=%2fpowershell%2fmodule%2ftoc.json
# https://docs.microsoft.com/en-us/powershell/module/az.sql/new-azsqldatabase?view=azps-2.5.0

#prerequisite: install PowerShell Core 6.x or later https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-6
install-module Az -AllowClobber  #https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-2.7.0
Import-Module Az   -Verbose
Update-Module Az -Verbose
#Uninstall-AzureRm

#Script Variables
$subscriptionName = "enter subscription name" 
$rg1="rg1"
#$rg2="rg12b-rg"
$location="eastus"
$location2="eastus2"
$adminSQLLogin="enter sql admin login name"
$adminSQLLoginPwd="enter password here"
$sqlserver1="azure sql logical server name"
$sqlserver2="azure sql logical server name 2"
$db_gp="db1"
$db_bc="db1_provisioned_bc"
$db_prem="db1_provisioned_prem"
$db_serverless="db1_serverless_gp"
$db_hyperscale="db1_hyperscale"
$edb1="edb1"
$edb2="edb2"
$edb3="edb3"


# HELPER FUNCTIONS -------------------------------------------
#get service endpoint info
Get-AzVirtualNetwork | select @{n="vnetname";e={$_.Name}} -ExpandProperty Subnets | select vnetname, Name, AddressPrefix, ServiceEndpoints | ft  -Wrap

#get global service tags info
$serviceTags = Get-AzNetworkServiceTag -Location eastus2
$serviceTags.Values | Where-Object { $_.Name -like "Sql*" -and $_.Properties.Region -eq "eastus2"}

#check if NSGs are using service tags
get-AzNetworkSecurityGroup | Select @{n="NSGname";e={$_.Name}} -ExpandProperty SecurityRules | Select NSGname,
    Name,Protocol, SourceAddressPrefix, SourcePortRange,
    DestinationAddressPrefix, DestinationPortRange, Access, Direction | ft -AutoSize -Wrap

#check SQL connection policy
#https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connectivity-architecture#script-to-change-connection-settings-via-powershell
# HELPER FUNCTIONS ------------------------------------------- /

# Create Azure SQL DB  --------------------
#Set subscription context
if(-not ((Get-AzContext).Subscription.name -eq $subscriptionName))
{
  Connect-AzAccount -Subscription $subscriptionName
  #get subscription id. Set script context to use this subscription
  $subscriptionId=Get-AzSubscription -SubscriptionName $subscriptionName  | select-object -ExpandProperty Id
  Set-AzContext -Subscription $subscriptionId
  Get-AzContext
}

#create resource group
if (-not (Get-AzResourceGroup $rg1)){
    New-AzResourceGroup -Name $rg1 -Location $location}

#create resource group for failover group secondary
if (-not (Get-AzResourceGroup $rg2)){
    New-AzResourceGroup -Name $rg2 -Location $location2}

## STEP1 *************
# Create a logical server with a system wide unique server name
New-AzSqlServer -ResourceGroupName $rg1 `
    -ServerName $sqlserver1 `
    -Location $location `
    -SqlAdministratorCredentials `
        $(New-Object -TypeName System.Management.Automation.PSCredential `
         -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString `
         -String $adminSQLLoginPwd -AsPlainText -Force))


# # Create a logical secondary server with a system wide unique server name
New-AzSqlServer -ResourceGroupName $rg2 `
-ServerName $sqlserver2 `
-Location $location2 `
-SqlAdministratorCredentials `
    $(New-Object -TypeName System.Management.Automation.PSCredential `
     -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString `
     -String $adminSQLLoginPwd -AsPlainText -Force))


## STEP 1b *************
#get client machine's public ip address to be added to SQL Server Firewall
$mypublicipaddress=Invoke-RestMethod http://ipinfo.io/json | Select-object -ExpandProperty ip
$startIp=$mypublicipaddress
$endIp=$mypublicipaddress
$endIp

# Update Firewall
New-AzSqlServerFirewallRule -ResourceGroupName $rg1 `
     -ServerName $sqlserver1 `
     -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
New-AzSqlServerFirewallRule -ResourceGroupName $rg2 `
     -ServerName $sqlserver2 `
     -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
 


#STEP 2 ******************************
#Create database(s): Choose option A-F
# ************************************

##########################################################################################################
# Option A: create premium tier database
##########################################################################################################
# Create a AdeventureWorks sample database with an P2 performance level, read scale enabled, zone redundant
#https://docs.microsoft.com/en-us/azure/availability-zones/az-overview#services-support-by-region

#Remove-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1 -DatabaseName $db_prem
New-AzSqlDatabase  -ResourceGroupName $rg1 -ServerName $sqlserver1 `
    -DatabaseName $db_prem -Edition Premium    -RequestedServiceObjectiveName "P2" `
    -SampleName "AdventureWorksLT" -ReadScale "Enabled" -ZoneRedundant -MaxSizeBytes  1GB
    #-WhatIf

##########################################################################################################
# Option B: create general  purpose tier db
##########################################################################################################
New-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1  `
    -DatabaseName $db_gp -Edition GeneralPurpose  `
    -SampleName "AdventureWorksLT"  -MaxSizeBytes 1GB `
    -VCore 2 -ComputeGeneration "Gen5" -LicenseType BasePrice <#Baseprice = AHB discounted pricing#>
    #gen5  4 vcore = 4 logical core = 2 physical hyperthreaded cores -ReadScale "Enabled" -ZoneRedundant

##########################################################################################################
# Option C: create business critical tier db
##########################################################################################################
# Create a  database with a BC tier, 4 vcores, read scale enabled, zone redundant, AHB LicenseType
#* Azure Hybrid benefit: #https://docs.microsoft.com/en-us/powershell/module/az.sql/new-azsqldatabase?view=azps-2.5.0

#gen4 vs gen5 https://stackoverflow.com/questions/54515870/azure-sql-managed-instance-gen4-and-gen5-hardware-choices

#Remove-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1 -DatabaseName $db_bc
New-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1  `
    -DatabaseName $db_bc -Edition BusinessCritical  `
    -SampleName "AdventureWorksLT" -ReadScale "Enabled" -ZoneRedundant -MaxSizeBytes 1GB `
    -VCore 4 -ComputeGeneration "Gen5" -LicenseType BasePrice <#Baseprice = AHB discounted pricing#>
    #gen5  4 vcore = 4 logical core = 2 physical hyperthreaded cores

##########################################################################################################
## Option D:  create serverless db - private preview
##########################################################################################################
#Remove-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1 -DatabaseName $db_serverless
$db_serverless="db11serverless_gp"
#$db_serverless="db2_serverless_gp"
New-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1  `
    -DatabaseName $db_serverless -Edition GeneralPurpose  `
    -MaxSizeBytes 1GB `
    -VCore 4 -ComputeGeneration "Gen5" -ComputeModel Serverless `
    -AutoPauseDelayInMinutes 60 -MinimumCapacity 1
    #-SampleName "AdventureWorksLT" 

##########################################################################################################
# # Option E: create hyperscale database
##########################################################################################################
# Create a  database with a hyperscale tier, 4 vcores, read scale enabled, AHB LicenseType
#* Azure Hybrid benefit: #https://docs.microsoft.com/en-us/powershell/module/az.sql/new-azsqldatabase?view=azps-2.5.0
#gen4 vs gen5 https://stackoverflow.com/questions/54515870/azure-sql-managed-instance-gen4-and-gen5-hardware-choices

#Remove-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1 -DatabaseName $db_hyperscale
New-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1  `
    -DatabaseName $db_hyperscale -Edition hyperscale  `
    -SampleName "AdventureWorksLT" -ReadScale "Enabled" `
    -VCore 4 -ComputeGeneration "Gen5" -LicenseType  BasePrice  <#Baseprice = AHB discounted pricing#>
    #gen5  4 vcore = 4 logical core = 2 physical hyperthreaded cores -MaxSizeBytes 1GB
    #-ZoneRedundant

##########################################################################################################
# Option F: create elastic pool with AHDB, zone redundant and add elastic pool dbs
##########################################################################################################
New-AzSqlElasticPool -ResourceGroupName $rg1 -ServerName $sqlserver1 `
    -ElasticPoolName "ePool1" -Edition BusinessCritical `
    -VCore 4 -ComputeGeneration "Gen5" -LicenseType BasePrice -StorageMB 32KB -ZoneRedundant

New-AzSqlDatabase -ResourceGroupName $rg1 -ServerName $sqlserver1  `
    -DatabaseName $edb1  -Edition BusinessCritical  `
    -SampleName "AdventureWorksLT" -ReadScale "Enabled" -ZoneRedundant -MaxSizeBytes 1GB `
    -VCore 2 -ComputeGeneration "Gen5" -LicenseType BasePrice
      <#Baseprice = AHB discounted pricing#>
    #gen5  4 vcore = 4 logical core = 2 physical hyperthreaded cores

New-AzSqlDatabase  -ResourceGroupName $rg1 -ServerName $sqlserver1 `
    -DatabaseName $edb2 -Edition Premium    -RequestedServiceObjectiveName "P2" `
    -SampleName "AdventureWorksLT" -ReadScale "Enabled" -ZoneRedundant -MaxSizeBytes  1GB
    #-WhatIf

New-AzSqlDatabase  -ResourceGroupName $rg1 -ServerName $sqlserver1 `
    -DatabaseName $edb3 -Edition GeneralPurpose    -VCore 2 `
    -SampleName "AdventureWorksLT"  -MaxSizeBytes  1GB -ComputeGeneration gen4
    #-WhatIf

##########################################################################################################
#Failover Secondary option: create elastic pool failover group (incomplete)
##########################################################################################################
# #must create an elastic pool with the same name on the secondary server
New-AzSqlElasticPool -ResourceGroupName $rg2 -ServerName $sqlserver2 `
    -ElasticPoolName "ePool1" -Edition BusinessCritical `
    -VCore 4 -ComputeGeneration "Gen5" -LicenseType BasePrice -StorageMB 32KB -ZoneRedundant

#list db's
Get-AzSqlDatabase -ServerName $sqlserver1 -ResourceGroupName $rg1 | 
    Select-Object ServerName,DatabaseName, Location, CurrentServiceObjectiveName, ReadScale, ZoneRedundant, LicenseType | 
    ft -AutoSize

Get-AzSqlDatabase -ServerName $sqlserver2 -ResourceGroupName $rg2 | 
    Select-Object ServerName,DatabaseName, Location, CurrentServiceObjectiveName, ReadScale, ZoneRedundant, LicenseType | 
    ft -AutoSize

#list elastic pools
Get-AzSqlElasticPool -ServerName $sqlserver2 -ResourceGroupName $rg2 |
    Select-Object ElasticPoolName, Location, SkuName, StorageMB, ZoneRedundant, Capacity |
    ft -AutoSize

# Add-AzSqlDatabaseToFailoverGroup ....