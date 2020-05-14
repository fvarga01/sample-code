#Replace special characters in a filename (such as spaces and parenthesis) with the "-" character
#Regular expression explanation:
#[\W]?   one or more special characters
#[^\.\w] exclude the file extension


$path =''
Get-ChildItem $path -Recurse <# -Filter “*Newsletter*” #>| Rename-Item -NewName {$_.name -replace ‘[\W]?[^\.\w]’, '-' -replace '-\.','.'}
