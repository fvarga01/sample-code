     param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
        [ValidateSet('WorkSheet1','WorkSheet2','WorkSheet3')]
        [string] $WORKSHEETNAME,
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [ValidateScript ({[System.IO.Directory]::Exists($_)})]
        [string] $CENTRALSHARE,
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=2)]
        [string] $SQLNETWORKNAME,
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=3)]
        [string] $SQLDB
        )
<#
Script must run from a machine with Excel installed.

 This script exports each worksheet from WorkSheet1.xlsx first into a CSV file, then into a SQL Server table.
 Exporting into CSV first allows us to easily bulk insert the data into SQL via the bulk insert command.
#>
$EXCELFILE = @{WorkSheet1="$CENTRALSHARE\WorkSheet1.xlsx"; 
    WorkSheet2="$CENTRALSHARE\WorkSheet2.xlsx";
    WorkSheet3="$CENTRALSHARE\WorkSheet3.xlsx"};

Set-Location c:\ #invoke-sqlcommand changes the current psdrive

<#
    Helper logging functions for easy switching of logging method
#>
function WriteLog
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [ValidateNotNullorEmpty()]
        [string] $str
    )
    write-host ( $env:COMPUTERNAME + ": " + $str )
}

<#
    Import a CSV file into SQL Server.
#>
function BulkInsertCSVIntoSQL
{
     param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
        [ValidateNotNullorEmpty()]
        [string] $csvFile,

        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [ValidateNotNullorEmpty()]
        [string] $tableName
    )

    $csvFile2="'"+$csvFile+"'"
    $tableName="dbo."+$tableName
    $BULKINS="use $SQLDB
    go
    bulk insert $tableName from $csvFile2
    with
    (
	    DATAFILETYPE='char',
	    ROWS_PER_WorkSheet3=10000,
	    FIRSTROW=2,
	    TABLOCK,
	    MAXERRORS=1000,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n'
    );select 1 as ReturnStatus;
    go"

    
    writelog $BULKINS
    $ret=Invoke-Sqlcmd -Query $BULKINS -ServerInstance $SQLNETWORKNAME -Database $SQLDB
	$ret=$ret.ReturnStatus;
    if(-not $ret)
         {writelog ("Failed to bulk insert $tableName from $csvFile2.");}
    else
        {
            writelog ("Bulk inserted $tableName from $csvFile2.");
            Remove-Item -LiteralPath $csvFile
            }
}

<#
    Export Excel worksheets to a CSV file.
#>
function ExportWStoCSV
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
        [ValidateNotNullorEmpty()]
        [string] $excelFile,

        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [ValidateNotNullorEmpty()]
        [string] $excelWS,

        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [ValidateNotNullorEmpty()]
        [string] $CENTRALSHARE
    )
    try{
        $E = New-Object -ComObject Excel.Application
        $E.Visible = $false
        $E.DisplayAlerts = $false
        $wb = $E.Workbooks.Open($excelFile)
        $ws=$wb.Worksheets.Item($excelWS)
        
        if($ws)
        {
            $n = join-path $CENTRALSHARE ("out."+$excelWS + ".csv")
            writelog("Writing temporary output CSV file: " + $n)
            $ws.SaveAs($n , 6)
            $E.Workbooks.Close()
            #Cannot simply import csv into sql here because of File In Use error from Excel.
        }#>
    }catch{
        $Error
        writelog($Error[0].Exception)
        writelog($Error[0].ScriptStackTrace)
    }
    finally{
        $E.Quit()
    }
}

#Export Excel worksheet to CSV:
writelog "Exporting Excel worksheet to a temporary CSV file."
ExportWStoCSV -excelFile $EXCELFILE[$WORKSHEETNAME] -CENTRALSHARE $CENTRALSHARE -excelWS $WORKSHEETNAME

$csvOutfile=join-path $CENTRALSHARE ("out.$WORKSHEETNAME.csv")

#WorkSheet3 table has an identity column (1st column) and a timestamp column
# with a default value of getdata (last column)
#must prepend with null value for identity column (first column) 
# + null value for last column
#-or- specify a format file, choosing to prepend + append each line instead
if($WORKSHEETNAME -eq "WorkSheet3")
{
    $newlines=new-object string[] 100 #intialize array of 100 elements
    
    $lines=get-content $csvOutfile
    foreach($l in $lines)
    {
        $newlines+=","+$l + ","
    }
    Set-Content $csvOutfile -Value $newlines
}

#Bulk insert each CSV file into SQL:
writelog "Bulk Inserting temporary CSV file into SQL Server" 
BulkInsertCSVIntoSQL -csvFile $csvOutfile  -tableName $WORKSHEETNAME

