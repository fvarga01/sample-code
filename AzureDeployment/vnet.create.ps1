# Script Purpose: Create Azure VNET, subnets, NSG via PowerShell

#https://docs.microsoft.com/en-us/azure/virtual-network/scripts/virtual-network-powershell-sample-multi-tier-application

Import-Module Az -Verbose
Update-Module Az -Verbose
#Uninstall-AzureRm

#Script Variables
$subscriptionName = "enter subscription name" 
Connect-AzAccount -Subscription $subscriptionName
Get-AzContext
#########################################################
#########################################################
#########################################################
$rgname="enter rg name"
$vnetname="enter vnet name"
$locationname="eastus"
if( -not (Get-AzResourceGroup -Name $rgname) )  { New-AzResourceGroup -Name $rgname -Location $locationname } 

#create NSG Rules
# Create an NSG rule to allow RDP traffic from the Internet to the front-end subnet.
$frontendrule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389
  
# Create an NSG rule to allow SQL traffic from the front-end subnet to the back-end subnet.
$backendrule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-SQL' -Description "Allow SQL" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
-SourceAddressPrefix "10.0.1.0/26" -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange 1433

#Create NSGs
# Create a network security group for the front-end subnet.
$frontendnsg = New-AzNetworkSecurityGroup -ResourceGroupName $rgname `
    -Location $locationname -Name 'frontend-nsg' `
    -SecurityRules $frontendrule1

    # Create a network security group for back-end subnet.
$backendnsg = New-AzNetworkSecurityGroup -ResourceGroupName $rgname `
    -Location $locationname -Name "backend-nsg" `
    -SecurityRules $backendrule1

$snet1=New-AzVirtualNetworkSubnetConfig -Name "frontend" `
 -AddressPrefix "10.0.1.0/26" -NetworkSecurityGroup $frontendnsg
$snet2=New-AzVirtualNetworkSubnetConfig -Name "infra" -AddressPrefix "10.0.2.0/26"
$snet3=New-AzVirtualNetworkSubnetConfig -Name "app" -AddressPrefix "10.0.3.0/26"
$snet4=New-AzVirtualNetworkSubnetConfig -Name "data" `
    -AddressPrefix "10.0.4.0/26" -NetworkSecurityGroup $backendnsg

New-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rgname `
    -Location $locationname -Subnet $snet1, $snet2, $snet3, $snet4 `
     -AddressPrefix "10.0.0.0/16"


<#add a subnet to an existing vnet
$vnet=Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rgname
Add-AzVirtualNetworkSubnetConfig -Name "subnet5" -VirtualNetwork $vnet -AddressPrefix "10.0.5.0/26"
$vnet | Set-AzVirtualNetwork
#>