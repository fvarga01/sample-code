write-host "******************** ODBC Drivers ****************************************"
Get-OdbcDriver -Platform 'All' | foreach {
    $attr = $_ | select -ExpandProperty Attribute
    New-Object -TypeName PSObject -Property @{
        ComputerName = $env:COMPUTERNAME
        Name = $_.Name
        Platform = $_.Platform
        Driver  =  $obj2["Driver"]
        DriverODBCVer  =  $obj2["DriverODBCVer"]
        } 
    } | select Computername, Name,Platform, DriverODBCVer,Driver  | ft

write-host "******************** ODBC DSNs ****************************************"
Get-OdbcDsn -Platform All -Name "fcvsqlserverea" | foreach {
    $attr = $_ | select -ExpandProperty Attribute
    $_ | select Name, DsnType, Platform, DriverName | select * | ft
    $attr
}

