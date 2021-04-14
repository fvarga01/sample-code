<#
Enumerate all of the volumes on the machine
#>
$Capacity =
@{
    Expression={[int] ($_.Capacity/1GB)}
    Name="Capacity (GB)"
}

$FreeSpace =
@{
    Expression={[int] ($_.FreeSpace/1GB)}
    Name="FreeSpace (GB)"
}

Get-CimInstance win32_volume |
    where-object {$_.filesystem -match "ntfs"} |
    format-table name, $Capacity, $FreeSpace, BlockSize
