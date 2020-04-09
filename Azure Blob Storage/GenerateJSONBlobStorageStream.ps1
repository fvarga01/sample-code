
#reference:
#https://docs.microsoft.com/en-us/powershell/module/az.storage/set-azstorageblobcontent?view=azps-3.7.0

#Global Variables
#these files should reside in same directory as ps1 file
$JSONCONFIGFILE = "appsettings.json" 
$JSONTEMPLATEFILE = "DeviceStream_template.json"
new-variable -Name CONFIG -Value (get-content $JSONCONFIGFILE -Raw | ConvertFrom-Json) -Option Constant -ErrorAction Ignore
Function UploadJSONFiles {
    Param (
        [string] $StorageContainer
    )
    $StorageAccountName = $CONFIG.BlobStorageAccountName;
    $StorageAccessKey = $CONFIG.BlobAccessKey;
    $StorageContainer = $CONFIG.BlobContainer
    $StorageAccountRG= $CONFIG.BlobResourceGroup

    #$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccessKey
    $StorageContext = (Get-AzStorageAccount $StorageAccountRG -Name $StorageAccountName ).Context

    $targetMIME = "application/octet-stream"
    $files = Get-ChildItem -Path .  -Filter "file_*.json"
    foreach ($file in $files) {
        Set-AzStorageBlobContent -File $file.FullName -Container $StorageContainer -Blob ("2020/04/09/" + $file.Name) -Properties @{"ContentType" = "$targetMIME"} -Context $StorageContext -Force
    } 
    $files | Remove-Item #delete local json files
 }

function StreamJSONFiles
{
    
    # $StorageAccountName = $CONFIG.BlobStorageAccountName;
    # $StorageAccessKey = $CONFIG.BlobAccessKey;
    # $StorageContainer = $CONFIG.BlobContainer
    # $StorageAccountRG= $CONFIG.BlobResourceGroup

    # #$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccessKey
    # $StorageContext = (Get-AzStorageAccount $StorageAccountRG -Name $StorageAccountName ).Context
    $jsoncontent = $null
    $jsoncontent=Get-Content $JSONTEMPLATEFILE| ConvertFrom-Json

    $ctr=0
    $rd="y";

    do{
        $batchSize = 5
        for ($i = 0; $i -lt $batchSize; $i++) {
            #update json object
            $jsoncontent.DeviceId = $ctr;
            $jsoncontent.SensorReadings.CustomSensor03[0] = $ctr;
            #write json to local file system
            $filename = "file_$ctr.json";
            $jsoncontent | ConvertTo-Json | Out-File $filename
            $ctr++
        }
        #copy batch of local json files to Azure Blob Storage
        UploadJSONFiles ($StorageContainer)
        start-sleep 30
        #$rd=Read-Host "Continue? Enter N or ctrl-c to stop."
    }while(  $rd -ne "n")
}

StreamJSONFiles


