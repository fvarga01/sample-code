<#
Map Cluster Shared Volume name to Physical Disk
This is useful when trying to decipher permon (sysmon) physical disk counters.
Although, now you can use the CSV specific perfmon(sysmon) counters for greater clarity.
#>
cls
$nodes=Get-ClusterNode | 
    Select-Object -ExpandProperty Name
$vols=[PSObject] @()
$AllLocalPartitions = Get-Partition | 
    select-object DiskNumber, AccessPaths | 
    Where-Object {$_.AccessPaths -and ($_.AccessPaths.Count -gt 0)  }  #only collect non-null access paths
foreach($clusterNode in $nodes)
{
    
    $s=New-CimSession -ComputerName $clusterNode
    
    
    $onlineDisks=get-disk -CimSession $s | 
        Where-Object {$_.OperationalStatus -eq "Online" } | 
        Select-Object FriendlyName, Guid, PartitionStyle, BusType, Manufacturer,  UniqueId, Number
    foreach($dsk in $onlineDisks)
    {
        
        $partition=Get-Partition -DiskNumber $dsk.Number -CimSession $s | 
            where-object {$_.AccessPaths -and ($_.AccessPaths.Count -gt 0)  `
                -and  ($_.OperationalStatus -eq "Online")}
        $vol=$partition | Get-Volume -Partition {$_} -CimSession $s | 
            Where-Object {$_.FileSystem -eq "CSVFS"} | 
            Select-Object FileSystem, FileSystemLabel 
        
        $LocalPartition = $null
        $LocalPartition= $AllLocalPartitions |
            Where-Object {$_.AccessPaths[0] -eq $partition.AccessPaths[0]} 
        
        if ($LocalPartition) 
        {
            "."
            $LocalDiskNum = $null
            if($partition.DiskNumber -ne $LocalPartition.DiskNumber) `
                {$LocalDiskNum = $LocalPartition.DiskNumber} #Only display LocalDiskNum if different

           $vol=  (New-Object -TypeName PSObject -Property @{ 
            "NodeName"=$clusterNode
            "RemoteDiskNum" = $partition.DiskNumber
            "LocalDiskNum" = $LocalDiskNum
            #"LocalPartAccessPaths"= $LocalPartition.AccessPaths[0]
            "PartAccessPath"= $partition.AccessPaths[0]
            "VolFileSystemLabel"=$vol.FileSystemLabel
            "VolFileSystem"=$vol.FileSystem
            } |  Where-Object {$_.VolFileSystem -eq "CSVFS"} ) 
            

            $vols += $vol
        }
    }
}
$vols | sort-object PartAccessPath | 
    Select-Object PartAccessPath, RemoteDiskNum,LocalDiskNum, NodeName |
    Format-Table -AutoSize
