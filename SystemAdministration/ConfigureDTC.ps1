<#
  This script was used to enable DTC between two untrusted machines with no name resolution between them
  # https://technet.microsoft.com/en-us/library/cc725913.aspx. 
  # https://docs.microsoft.com/en-us/sql/sql-server/install/configure-the-windows-firewall-to-allow-sql-server-access 
#>
#----------------------------------------------------
#FIREWALL -------------------------------------------
# Confirm DTC firewall port 135 is opened
# Using the pre-configured Distributed Transaction Coordinator Firewall Rules
#----------------------------------------------------

#Check firewall
Get-NetFirewallProfile |
    Select-Object Name, Enabled, DefaultOutboundAction, DefaultInboundAction |
    Format-Table -AutoSize
Get-NetFirewallRule |
    Where-Object{$_.Name -like "MSDTC-*" -or $_.DisplayGroup-like "*WMI*"} |
     Select-Object Name,Enabled, DisplayName, DisplayGroup |  Format-Table -AutoSize
               
#check dtc dynamic ports
netsh int ipv4 show dynamicport tcp
#confirm dtc process is listening on port 135
netstat -bano | select-string  -SimpleMatch "0:6","0:1433","0:135" -Context 0,1  #,"sql""RPC","msdtc","wininit"
               
#configure Windows firewall
Set-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -Enabled True
Set-NetFirewallRule -DisplayGroup "Distributed Transaction Coordinator" -Enabled True

New-NetFirewallRule -Name "contoso-DTC-DynamicPorts" -DisplayName  "contoso-DTC-DynamicPorts" -LocalPort 60000-60022 -Enabled True -Protocol tcp -Direction Inbound
New-NetFirewallRule -Name "Ocontoso-DTC-DynamicPorts" -DisplayName  "Ocontoso-DTC-DynamicPorts" -LocalPort 60000-60022 -Enabled True -Protocol tcp -Direction Outbound
New-NetFirewallRule -Name "contoso-SQL" -DisplayName  "contoso-SQL" -LocalPort 1433 -Enabled True -Protocol tcp -Direction Inbound
New-NetFirewallRule -Name "Ocontoso-SQL" -DisplayName  "Ocontoso-SQL" -LocalPort 1433 -Enabled True -Protocol tcp -Direction Outbound

#Check firewall
Get-NetFirewallRule |
    Where-Object{$_.Name -like "MSDTC-*" -or $_.DisplayGroup-like "*WMI*"} |
    Select-Object Name,Enabled,Action , DisplayName, DisplayGroup |
    Format-Table -AutoSize
Get-NetFirewallRule |
    Where-Object{$_.Name -like "*contoso*"}|
    Select-Object Name,Enabled,Action, DisplayName |
    Format-Table -AutoSize
#----------------------------------------------------
# DTC Security --------------------------------------
#----------------------------------------------------
Get-DtcNetworkSetting  | ft –autosize
Set-DtcNetworkSetting -AuthenticationLevel NoAuth -DtcName "Local" -InboundTransactionsEnabled $True -LUTransactionsEnabled $True -OutboundTransactionsEnabled $True -RemoteAdministrationAccessEnabled $False -RemoteClientAccessEnabled $False -XATransactionsEnabled $True
Get-DtcNetworkSetting  | ft –autosize

#**** limit dtc ports start->run>dcomcnfg *****

#----------------------------------------------------
#Test -----------------------------------------------
#----------------------------------------------------

$server1IPAddress="1.2.3.4"
#Name resolution must be configured so that ping by netbios works  -  add LMHOSTS.sam entry
Get-Content C:\Windows\System32\drivers\etc\lmhosts.sam -Tail 5
Get-Content C:\Windows\System32\drivers\etc\hosts -Tail 5
add-content C:\Windows\System32\drivers\etc\hosts -Value "`r`n$server1IPAddress`tServer1"
add-content C:\Windows\System32\drivers\etc\lmhosts.sam -Value "`r`n$server1IPAddress`tServer1"

ipconfig /flushdns

Test-NetConnection -ComputerName Server1 -Port 135 -InformationLevel Detailed
Test-NetConnection -ComputerName Server1 -Port 1433 -InformationLevel Detailed

#test local dtc connection settings
test-dtc -LocalComputerName $env:computername -verbose 

#test remote dtc connection
#Open port 80 for test-dtc process to listen on
# requires WMI/CIM session - so may need to skip this if WinMgmt not enabled
New-NetFirewallRule -Name "testDtc1" -DisplayName "testDtc1" -LocalPort 80 -Enabled True -Protocol tcp
Get-NetFirewallRule | ?{$_.DisplayName -like "*testDtc1*"} |
    Select-Object * | Format-Table -AutoSize
test-dtc -LocalComputerName $env:computername -RemoteComputerName "Server1"  -verbose -ResourceManagerPort 80 # 17100 #port 0 by default
Remove-NetFirewallRule -Name "testDtc1"
<# In SQL Server - add linked server
USE [master]
GO
EXEC master.dbo.sp_addlinkedserver @server = N'Server1', @srvproduct=N'SQL Server'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'Server1',@useself=N'False',
    @locallogin=NULL,@rmtuser=N'username',@rmtpassword='########'
GO
#>
Invoke-Sqlcmd -ServerInstance Server1 `
    -Query "begin distributed tran;select name from [Server1].master.sys.databases;waitfor delay '0:0:30';commit" -QueryTimeout 60
