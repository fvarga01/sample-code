#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
#                        ENUMERATE ODBC DRIVERS AND ODBC DSNs
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************

write-host "******************** List ODBC Drivers ****************************************"
Get-OdbcDriver -Platform 'All' | where-object {$_.Name -notlike "*Microsoft*(*.*)*" } | 
    select  @{n='DriverODBCVer';e={$env:COMPUTERNAME}, Name,Platform,
        @{n='DriverODBCVer';e={$_.Attribute.DriverODBCVer}},@{n='Driver';e={$_.Attribute.Driver}},
        @{n='DriverFileVer';e={[string] ((Get-Item $_.Attribute.Driver -ErrorAction SilentlyContinue).VersionInfo.FileVersion)}} | ft


write-host "******************** List ODBC DSNs ****************************************"
#Get-ODBCDSN |  select Name, DsnType, Platform, DriverName, @{n='Server';e={$_.Attribute.server}} | ft
Get-OdbcDsn -Platform All | where-object {$_.Platform -ne 'Unknown Platform'}  |
    foreach {
        $attr = $_ | select -ExpandProperty Attribute
        #filter out empty property values
        $attr= $attr.GetEnumerator() | Where-Object { $_.Value}

        #display dsn and non-empty attributes
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

#utility function which converts a hastbale object to a string array
function convert-HashToStringArray([hashtable] $HashTableObject)
{
    $stringNonemptyAttributes = @() #format must be an array of strings where each string has a Key=Value format

    #filter out empty property values
    $htArr = $HashTableObject.GetEnumerator() | Where-Object { $_.Value}
    $htArr | ForEach-Object { $stringNonemptyAttributes+= "$($_.Key)=$($_.Value)"}
    return  $stringNonemptyAttributes;

}

#create a remote CIM Session
#New-CIMSession: https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/new-cimsession?view=powershell-7
$remoteCIMSession= New-CimSession -ComputerName "****ENTER REMOTE COMPUTERNAME HERE*****"
$extractedDSNs=Get-OdbcDsn -Platform All | where-object {$_.Platform -ne 'Unknown Platform'} 
$extractedDSNs | foreach {
 Add-OdbcDsn -Name $_.Name -DsnType $_.DsnType -Platform $_.Platform -DriverName $_.DriverName -SetPropertyValue (convert-HashToStringArray $_.Attribute) -CimSession $remoteCIMSession
}

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

write-host "******************** Updating XML file to ensure correct Platform string ****************************************"
#User DSNs can show up as both 32 + 64 bit, platform = "32/64-bit": https://docs.microsoft.com/en-us/previous-versions/windows/desktop/odbc/dn170537(v=vs.85)
# Replacing string '32/64-bit' to '64-bit' to workaround for error:
# Add-OdbcDsn : Cannot validate argument on parameter 'Platform'.
# The argument "32/64-bit" does not belong to the set "32-bit,64-bit" specified by the ValidateSet attribute.
# Supply an argument that is in the set and then try the command again.
((Get-Content -path $XmlFilePath -Raw) -replace '32/64-bit','64-bit') | Set-Content -Path $XmlFilePath


#******************************************************************************************************
#*********** Part 2: Steps below are to be executed on the destination (new) machine ****************************************
#******************************************************************************************************
#Note: Adding a SYSTEM level DSN is a privileged operation. ***YOU MUST RUNAS ADMINISTRATOR***, or the following error will be raised:
#    Add-OdbcDsn : Access denied: low-privilege user cannot manage an ODBC System DSN.
#    To manage an ODBC System DSN, start Windows PowerShell with the "Run as administrator" option.



#utility function which converts a hastbale object to a string array
function convert-HashToStringArray([hashtable] $HashTableObject)
{
    $stringNonemptyAttributes = @() #format must be an array of strings where each string has a Key=Value format

    #filter out empty property values
    $htArr = $HashTableObject.GetEnumerator() | Where-Object { $_.Value}
    $htArr | ForEach-Object { $stringNonemptyAttributes+= "$($_.Key)=$($_.Value)"}
    return  $stringNonemptyAttributes;

}

write-host "******************** Importing ODBC DSNs from an XML file  ****************************************"
$XmlFilePath = "DSNs.xml"
$ImportedDSNs = Import-CLIXML -Path $XmlFilePath
#Loop through each imported DSN, build attribute string, add the DSN

$ImportedDSNs | foreach {
    #DEBUG:
    $pairedAttributeString=  "DSN=" +$_.Name + "|" + ((convert-HashToStringArray $_.Attribute) -join "|")
    $pairedAttributeString

    #Part2:OptA
    Add-OdbcDsn -Name $_.Name -DsnType $_.DsnType -Platform $_.Platform -DriverName $_.DriverName -SetPropertyValue (convert-HashToStringArray $_.Attribute)

    #Part2 OptB (using odbcconf tool)
    #64-bit system:
    #   odbcconf.exe configsysdsn "ODBC Driver 17 for SQL Server" "DSN=dsn1|SERVER=xyz.database.windows.net|Trusted_Connection=No|Database=AdventureWorksLT"
    #32-bit system:
    #   %windir%\syswow64\configdsn "ODBC Driver 17 for SQL Server" "DSN=dsn1|SERVER=xyz.database.windows.net|Trusted_Connection=No|Database=AdventureWorksLT"
    #if() ....user dsn....
    #if($_.Platform -eq '64-bit'){     odbcconf.exe configsysdsn $_.DriverName $pairedAttributeString     }
    #elseif($_.Platform -eq '64-bit'){     %windir%\syswow64\odbcconf.exe configsysdsn $_.DriverName $pairedAttributeString     }
 }
 

#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
# METHOD 3: Export/Import Registry Key
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************



#******************************************************************************************************
#*********** Part 1: Steps below are to be executed on the source machine ****************************************
#******************************************************************************************************

#https://docs.microsoft.com/en-us/sql/odbc/reference/install/registry-entries-for-data-sources?view=sql-server-ver15

#64-bit System: HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI
#32-bit System: HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI
#32/64 User: HKCU:\SOFTWARE\ODBC\ODBC.INI

#export via reg.exe: 
# regedit /e filename.reg "HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI"

$dsns = @()
#extract 64-bit system dsn, 32-bit system dsn, and user dsns
$rootPaths = @("HKLM:\SOFTWARE\ODBC\ODBC.INI\", "HKLM:SOFTWARE\Wow6432Node\ODBC\ODBC.INI\", "HKCU:\SOFTWARE\ODBC\ODBC.INI")
foreach($root in $rootPaths)
{
   $dsnNames=(Get-Item -path $root).GetSubKeyNames() |Where-Object {$_ -notin ("ODBC Data Sources","dBASE Files","Excel Files","MS Access Database") }
   foreach($dsnName in $dsnNames){
        $dsnKey = join-path $root $dsnName

        $propertyNames = get-item  -path $dsnKey | select -ExpandProperty Property
        
        $currDSNProperties = @{}
        $currDSNProperties.Add("PSPath",$dsnKey)
        foreach ($pn in $propertyNames) 
        {
            $value=Get-ItemProperty -path $dsnKey -Name $pn | select -ExpandProperty $pn
            $currDSNProperties.Add($pn, $value )
        }
        $dsns += $currDSNProperties
   }
}
$dsns | Export-CliXML "dsn_regkeys.xml"




#******************************************************************************************************
#*********** Part 2: Steps below are to be executed on the destination (new) machine ****************************************
#******************************************************************************************************
$dsnsToImport = Import-Clixml "dsn_regkeys.xml"
foreach ($dsn in $dsnsToImport)
{
    $dsnPath = $dsn["PSPath"]
    new-item $dsnPath
    $dsn.Keys | Where-Object {$_ -ne "PSPath"} | foreach{  New-ItemProperty -Path $dsnPath -Name $_ -Value $dsn[$_]}
}


#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
# If permitted by the ODBC driver, set Username + Passwords
#**************************************************************************************************************
#**************************************************************************************************************
#**************************************************************************************************************
#https://social.msdn.microsoft.com/Forums/sqlserver/en-US/d4eab3b3-6254-4644-a1e4-e6866f7507fd/uid-in-odbcini?forum=sqldataaccess
#https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqldriverconnect-function?view=sql-server-ver15
#Some drivers support storing username and password, most do not
#$Credential = Get-Credential
#New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\<DSNName> -PropertyType String -Name UID -Value $Credential.UserName
#New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\<DSNName> -PropertyType String -Name PWD -Value $Credential.GetNetworkCredential().password