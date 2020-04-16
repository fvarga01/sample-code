write-host "******************** ODBC Drivers ****************************************"
Get-OdbcDriver -Platform 'All' | foreach {
    $attr = $_ | select -ExpandProperty Attribute
    New-Object -TypeName PSObject -Property @{
        ComputerName = $env:COMPUTERNAME
        Name = $_.Name
        Platform = $_.Platform
        Driver  =  $attr["Driver"]
        DriverODBCVer  =  $attr["DriverODBCVer"]
        } 
    } | select Computername, Name,Platform, DriverODBCVer,Driver  | ft



write-host "******************** ODBC DSNs ****************************************"
Get-OdbcDsn -Platform All | foreach {
    $attr = $_ | select -ExpandProperty Attribute
    $_ | select Name, DsnType, Platform, DriverName | select * | ft
    $attr
}

