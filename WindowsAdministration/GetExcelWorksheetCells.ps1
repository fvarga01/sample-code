# This script writes values from Excel Worksheet cells into a text file
# This is useful should you need to extract just a small subset of 
# Excel Worksheet values
# The script must run on a machine where Microsoft Excel is installed
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
    [ValidateScript ({[System.IO.Directory]::Exists($_)})]
    [string] $CENTRALSHARE
)

$excelFile=join-path $CENTRALSHARE "WorkSheet1.xlsx" -Resolve | convert-path
$outFile=join-path $CENTRALSHARE "ExportedExcelColumns.out" 
$excelWS="WorkSheet1"
#specify column id's for columns of interest
$colColumn1=1 
$colColumn2=3
$colColumn3=4

try{
	remove-item $outFile -ErrorAction Ignore
    $E = New-Object -ComObject Excel.Application
    $E.Visible = $false
    $E.DisplayAlerts = $false
    $wb = $E.Workbooks.Open($excelFile)
    $ws=$wb.Worksheets.Item($excelWS)

    if($ws)
    {
        $RowCtr=1
        while(++$RowCtr -le $ws.UsedRange.Cells.Rows.Count)
        {
            $Column1 = $ws.Cells.Item($RowCtr, $colColumn1).Value()
            $Column2 = $ws.Cells.Item($RowCtr, $colColumn2).Value()
            $Column3 = $ws.Cells.Item($RowCtr, $colColumn3).Value()

            #write column values to the file
            "$Column1 $Column2 $Column3" | Out-File -FilePath $outFile -Append
            ""| Out-File -FilePath $outFile -Append
        }
    }

    $E.Workbooks.Close()
}catch{
        $Error
        $Error[0].Exception
        $Error[0].ScriptStackTrace
}finally{
        $E.Quit()
}