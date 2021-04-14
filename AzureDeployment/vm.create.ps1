<#
Pre-requisite: vnet.create.ps1
Import-Module Az -Verbose
#>

# Script Purpose: Create Azure Windows VM and attach to existing VNET subnet via PowerShell

#Logon to Az subscription
$subscriptionName = "enter subscription name" 

if(-not ((Get-AzContext).Subscription.name -eq $subscriptionName))
{
  Connect-AzAccount -Subscription $subscriptionName
}
#register the sqlvm provider at the subscription
#Register-AzResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine

#Variables
$site1location="eastus"
$site1infrarg="enter rg name"
$site1vnetname="enter vnet name"
$vms=@(
  @{vmname="sqlnode1";vmOffer="sql2019-ws2019";vmPublisher ="microsoftsqlserver";vmSku="sqldev";vmSize="Standard_B2ms"}
  ,@{vmname="sqlnode2";vmOffer="sql2019-ws2019";vmPublisher ="microsoftsqlserver";vmSku="sqldev";vmSize="Standard_B2ms"}
  ,@{vmname="jumpbox";vmOffer="WindowsServer";vmPublisher ="MicrosoftWindowsServer";vmSku="2016-Datacenter-smalldisk";vmSize="Standard_B2ms"}
  #,@{vmname="sqlnode1";;vmOffer="WindowsServer";vmPublisher ="MicrosoftWindowsServer";vmSku="2019-Datacenter-Core-smalldisk";vmSize="Standard_DS1_v2" }
)

#new vm admin credentials
$cred=Get-Credential

#create vm NIC and Public IP for jumpbox
$site1vnet = Get-AzVirtualNetwork -Name $site1vnetname `
                             -ResourceGroupName $site1infrarg
$frontendSubnetId= $site1vnet.Subnets.Where({$_.name -eq 'frontend'}).Id
$backendDataSubnetId= $site1vnet.Subnets.Where({$_.name -eq 'data'}).Id
$NIC = $null

foreach ($vm in $vms)
{

  if($vm.vmname -eq "jumpbox")
  {
    $vmpublicip = New-AzPublicIpAddress -Name ($vm.vmname +"-IP") `
      -ResourceGroupName $site1infrarg -Location $site1location `
      -AllocationMethod Dynamic

    $NIC = New-AzNetworkInterface -Name ($vm.vmname +"-NIC") `
                                -ResourceGroupName $site1infrarg `
                                -Location $site1location `
                                -SubnetId $frontendSubnetId `
                                -PublicIpAddressId $vmpublicip.Id
  }else {
    $NIC = New-AzNetworkInterface -Name ($vm.vmname +"-NIC") `
                                -ResourceGroupName $site1infrarg `
                                -Location $site1location `
                                -SubnetId $backendDataSubnetId
  }

  #configure vm properties
  $vmObj = New-AzVMConfig -VMName $vm.vmname `
    -VMSize $vm.vmSize
  $vmObj = Add-AzVMNetworkInterface -VM $vmObj `
    -Id $NIC.Id
  $vmObj = Set-AzVMOperatingSystem -VM $vmObj -Windows `
    -ProvisionVMAgent -EnableAutoUpdate `
    -ComputerName $vm.vmname -Credential $cred 
  $vmObj = Set-AzVMSourceImage -VM $vmObj `
    -PublisherName $vm.vmPublisher -Offer $vm.vmOffer `
    -Skus $vm.vmSku -Version latest 

  #ManagedDiskParameters.StorageAccountType Property https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.compute.models.manageddiskparameters.storageaccounttype?view=azure-dotnet
  $vmObj=Set-AzVMOSDisk -VM $vmObj `
    -Name ($vm.vmname+"-OsDisk") `
    -Caching ReadWrite -StorageAccountType "Standard_LRS" `
    -CreateOption FromImage   -DiskSizeInGB 127

  #create vm
  New-AzVm -VM $vmObj -ResourceGroupName $site1infrarg `
    -Location $site1location -Verbose
}



<#
get-AzVMImageSku -Location "eastus" `
  -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" |
  where {$_.Skus -like "*smalldisk*"}
get-AzVMSize -Location "eastus" #Standard_DS1_v2
get-AzVMImage -Location $site1location -PublisherName $publisher -Offer $offer -Skus $sku
#>

<#
Important: create an NSG

https://docs.microsoft.com/en-us/azure/virtual-network/security-overview#how-traffic-is-evaluated 
" All network traffic is allowed through a subnet and network interface if they don't have a network security group associated to them."
#>


<#Next Steps for SQL VMs:
1) configure sql auth
2) configure windows firewall rule within each windows vm to open necessary ports

New-NetFirewallRule -Name "contoso-SQL" -DisplayName  "contoso-SQL" -LocalPort 1433 `
    -Enabled True -Protocol tcp -Direction Inbound
New-NetFirewallRule -Name "Ocontoso-SQL" -DisplayName  "Ocontoso-SQL" -LocalPort 1433 `
    -Enabled True -Protocol tcp -Direction Outbound
#>