#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
#                        ENUMERATE ODBC DRIVERS AND ODBC DSNs
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************

write-host "******************** List ODBC Drivers ****************************************"
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



write-host "******************** List ODBC DSNs ****************************************"
Get-OdbcDsn -Platform All | where-object {$_.Platform -ne 'Unknown Platform'}  | foreach {
    $attr = $_ | select -ExpandProperty Attribute
    $_ | select Name, DsnType, Platform, DriverName | select * | ft
    $attr
}

#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
# METHOD 1: Import/Export object via remote CIM Session
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************

#New-CIMSession: https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/new-cimsession?view=powershell-7
$remoteCIMSession= New-CimSession -ComputerName "****ENTER REMOTE COMPUTERNAME HERE*****"
Get-OdbcDsn -Platform All | where-object {$_.Platform -ne 'Unknown Platform'} | Add-OdbcDsn -CimSession $remoteCIMSession



#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
# METHOD 2: Import/Export via XML File
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************

#******************************************************************************************************
#*********** Part 1: Steps below are to be executed on the source machine ****************************************
#******************************************************************************************************

write-host "******************** Exporting ODBC DSNs to an XML file  ****************************************"
$XmlFilePath = "DSNs.xml"
Get-OdbcDsn -Platform All | where-object {$_.Platform -ne 'Unknown Platform'} | select * -ExpandProperty Attribute | Export-CLIXML -Path $XmlFilePath -Depth 10 -Verbose

#/*** DEBUG ONLY***
#**Deleting DSN's for local testing only 
# Get-OdbcDsn -Platform All | where-object {$_.Platform -ne 'Unknown Platform' -and $_.name -like "*dummydsn"} | Remove-OdbcDsn
#renaming DSN for local testing only
# ((Get-Content -path $XmlFilePath -Raw) -replace 'uDSN3264','uDSN3264dummydsn') | Set-Content -Path $XmlFilePath
# ((Get-Content -path $XmlFilePath -Raw) -replace 'uDSN32','uDSN32dummydsn') | Set-Content -Path $XmlFilePath
# ((Get-Content -path $XmlFilePath -Raw) -replace 'sDSN32','sDSN32dummydsn') | Set-Content -Path $XmlFilePath
# ((Get-Content -path $XmlFilePath -Raw) -replace 'sDSN64','sDSN64dummydsn') | Set-Content -Path $XmlFilePath
# Get-OdbcDsn -Platform All | where-object {$_.Platform -ne 'Unknown Platform'} | ft
#*** DEBUG ONLY ***/

write-host "******************** Updating XML file to ensure correct Platform string ****************************************"
#Replacing string '32/64-bit' to Workaround for this error if a dsn can be used with both 32 + 63
#Some DSNs can show up as both 32 + 64 bit, platform = "32/64-bit": https://docs.microsoft.com/en-us/previous-versions/windows/desktop/odbc/dn170537(v=vs.85)
# Add-OdbcDsn : Cannot validate argument on parameter 'Platform'.
# The argument "32/64-bit" does not belong to the set "32-bit,64-bit" specified by the ValidateSet attribute.
# Supply an argument that is in the set and then try the command again.
((Get-Content -path $XmlFilePath -Raw) -replace '32/64-bit','64-bit') | Set-Content -Path $XmlFilePath


#******************************************************************************************************
#*********** Part 2: Steps below are to be executed on the destination (new) machine ****************************************
#******************************************************************************************************
#Note: Adding a SYSTEM level DSN is a privileged operation. You must RUNAS administrator, or the following error will be raised:
#Sample error: Add-OdbcDsn : Access denied: low-privilege user cannot manage an ODBC System DSN.
#    To manage an ODBC System DSN, start Windows PowerShell with the "Run as administrator" option.

write-host "******************** Importing ODBC DSNs from an XML file  ****************************************"
$XmlFilePath = "DSNs.xml"
$ImportedDSNs = Import-CLIXML -Path $XmlFilePath
#Loop through each imported DSN, build attribute string, add the DSN

#retrieve list of attributes used the DSN
foreach($dsn in $ImportedDSNs)
{ 
    $attributes = $dsn.Attribute
    $nonemptyAttributes=@{}
    $attributes.Keys | ForEach-Object {
        if($attributes[$_] -and ($attributes[$_].Length -ge 0))
        {
            $nonemptyAttributes.Add($_, $attributes[$_])
            #"Keeping " + $_ + "=" + $attributes[$_]
         
        }else
        {
            #"skipping " + $_ + "=" + $attributes[$_]
        }
    }

    #Build string array which contains list of attributes
    #ref: https://stackoverflow.com/questions/26008148/convert-a-hashtable-to-a-string-of-key-value-pairs
    #Extract into string key/value pairs required for the Add-OdbcDsn commandlet
    $stringNonemptyAttributes = @() #format must be an array of strings where each string has a Key=Value format
    #$stringNonemptyAttributes = ($nonemptyAttributes.GetEnumerator() | % { "$($_.Key)=$($_.Value)" })
    ($nonemptyAttributes.GetEnumerator() | ForEach-Object { $stringNonemptyAttributes+= "$($_.Key)=$($_.Value)"})

    #DEBUG: $dsn.Name + ": " + ($stringNonemptyAttributes -join " ; ")

   #add the odbc DSN
   Add-OdbcDsn -Name $dsn.Name -DriverName $dsn.DriverName  -Platform $dsn.Platform -DsnType $dsn.DsnType -SetPropertyValue $stringNonemptyAttributes
}