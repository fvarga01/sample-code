# Some programs add line breaks in unexpected places to a JSON file
# This script removes all line breaks from a JSON file,
# should you need to read it as a single line
param(
    [Parameter(Mandatory=$true, Position=0)]
       [ValidatePattern("\.(?i)(json)$")] #verify a JSON file is supplied
       [ValidateScript ({[System.IO.File]::Exists($_)})] #Verify file is accessible
       [string] $JSONFILE
)
$content=Get-Content $JSONFILE;
$content=([string]$content).Replace("`r`n","" );
Out-File -LiteralPath $JSONFILE -InputObject $content;