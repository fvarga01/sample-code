<#
Create pooled SQL Server connections
#>
$ConnectionString1 = "data source=servernamehere; initial catalog=dbnamehere; trusted_connection=true; application name=Pool1;max pool size=2" 
$ConnectionString2 = "data source=servernamehere; initial catalog=dbnamehere; trusted_connection=true; application name=Pool2;max pool size=2" 


$SqlPool1Conn1 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString1) 
$SqlPool1Conn2 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString1) 
$SqlPool2Conn1 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString2) 
$SqlPool2Conn2 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString2) 


$SqlPool1Conn1.Open() 
Start-Sleep -Seconds 1
$SqlPool1Conn2.Open() 
Start-Sleep -Seconds 1 
$SqlPool2Conn1.Open() 
Start-Sleep -Seconds 1 
$SqlPool2Conn2.Open() 
Start-Sleep -Seconds 1 

$cmd1 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(1,'Pool1:Conn1')" , $SqlPool1Conn1)
$cmd2 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(2,'Pool1:Conn2')" , $SqlPool1Conn2)
$cmd3 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(3,'Pool2:Conn1')" , $SqlPool2Conn1)
$cmd4 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(4,'Pool2:Conn2')" , $SqlPool2Conn2)

$cmd1.executenonquery()
$cmd2.executenonquery()
$cmd3.executenonquery()
$cmd4.executenonquery()

Start-Sleep -Seconds 2 
#select  session_id,program_name from sys.dm_exec_sessions where program_name like  'Pool1%'; 
$SqlPool1Conn1.Close() 
$SqlPool1Conn2.Close() 
$SqlPool2Conn1.Close() 
$SqlPool2Conn2.Close() 

Start-Sleep -Seconds 2 
Write-Host "SqlPool1Conn1 State: $($SqlPool1Conn1.State)" -ForegroundColor Green 
Write-Host "SqlPool1Conn2 State: $($SqlPool1Conn2.State)" -ForegroundColor Green 
Write-Host "SqlPool2Conn1 State: $($SqlPool2Conn1.State)" -ForegroundColor Green 
Write-Host "SqlPool2Conn2 State: $($SqlPool2Conn2.State)" -ForegroundColor Green 

$SqlPool1Conn3 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString1) 
$SqlPool1Conn3.Open() #because max pool is set to 2, must run this after 1 of 2 connections is closed for Pool1
$cmd5 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(5,'Pool1:Conn3')" , $SqlPool1Conn3)
$cmd5.executenonquery()
$SqlPool1Conn3.Close() 
Start-Sleep -Seconds 2
$SqlPool1Conn4 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString1) 
$SqlPool1Conn4.Open() #because max pool is set to 2, must run this after 1 of 2 connections is closed for Pool1
$cmd5 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(6,'Pool1:Conn4')" , $SqlPool1Conn4)
$cmd5.executenonquery()
$SqlPool1Conn4.Close() 
Start-Sleep -Seconds 2 


$SqlPool2Conn3 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString2) 
$SqlPool2Conn3.Open() #because max pool is set to 2, must run this after 1 of 2 connections is closed for Pool1
$cmd6 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(7,'Pool2:Conn3')" , $SqlPool2Conn3)
$cmd6.executenonquery()
$SqlPool2Conn3.Close() 
Start-Sleep -Seconds 2
$SqlPool2Conn4 = New-Object System.Data.SqlClient.SqlConnection($ConnectionString2) 
$SqlPool2Conn4.Open() #because max pool is set to 2, must run this after 1 of 2 connections is closed for Pool2
$cmd6 = New-Object System.Data.SqlClient.SqlCommand("insert into t1 values(8,'Pool2:Conn4')" , $SqlPool2Conn4)
$cmd6.executenonquery()
$SqlPool2Conn4.Close() 
Start-Sleep -Seconds 2 

Write-Host "SqlPool1Conn1 State: $($SqlPool1Conn1.State)" -ForegroundColor Green 
Write-Host "SqlPool1Conn2 State: $($SqlPool1Conn2.State)" -ForegroundColor Green 
Write-Host "SqlPool1Conn3 State: $($SqlPool1Conn3.State)" -ForegroundColor Green 
Write-Host "SqlPool1Conn4 State: $($SqlPool1Conn4.State)" -ForegroundColor Green 
Write-Host "SqlPool2Conn1 State: $($SqlPool2Conn1.State)" -ForegroundColor Green 
Write-Host "SqlPool2Conn2 State: $($SqlPool2Conn2.State)" -ForegroundColor Green 
Write-Host "SqlPool2Conn3 State: $($SqlPool2Conn3.State)" -ForegroundColor Green 
Write-Host "SqlPool2Conn4 State: $($SqlPool2Conn4.State)" -ForegroundColor Green 

#select  session_id,program_name from sys.dm_exec_sessions where program_name like 'Pool%'; 

<#
$SqlPool1Conn1.Dispose() 
$SqlPool1Conn2.Dispose() 
$SqlPool2Conn1.Dispose() 
$SqlPool2Conn2.Dispose() 

$SqlConnection1=$NULL
$SqlConnection2=$NULL
$SqlConnection3=$NULL
$SqlConnection4=$NULL
$SqlConnection5=$NULL


$cmd1.Dispose()
$cmd2.Dispose()
$cmd3.Dispose()
$cmd4.Dispose()
$cmd5.Dispose()

$cmd1 = $NULL
$cmd2 = $NULL
$cmd3 = $NULL
$cmd4 = $NULL
$cmd5 = $NULL
#>