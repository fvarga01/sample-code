<#
Review disk alignment and allocation details
#>
cls
$c="Server1"

#check partition offset # should be a whole number, no fractions
get-wmiobject win32_diskpartition -ComputerName $c | where-object {$_.Index -eq 0} | 
    Select-Object systemname, name, index, startingoffset, `
         @{Name="OffsetMB";Expression={$_.startingoffset/(1024*1024)}} | 
    Sort-Object OffsetMB|
    Format-Table -autosize


#Check allocation size
get-wmiobject win32_volume -ComputerName $c | 
    Select-Object PSComputerName, Name, Label,  blocksize | 
    sort-object blockSize |
    Format-Table -AutoSize

#Invoke-Command -ComputerName $c {fsutil fsinfo ntfsinfo u:} | where-object {$_ -match "Bytes per cluster"}
