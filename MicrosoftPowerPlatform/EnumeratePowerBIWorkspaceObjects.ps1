Install-Module -Name MicrosoftPowerBIMgmt
$pbiWSName="workspace name here"
$pbiWSId=$null
Connect-PowerBIServiceAccount
$pbiWSId = Get-PowerBIWorkspace -Name $pbiWSName | Select-Object -ExpandProperty Id
    #Select-Object Name, IsOnDedicatedCapactity, CapacityId, Id
$pbiWSId = $pbiWSId.Guid
Get-PowerBIDataset -WorkspaceId $pbiWSId | Select-Object  Name, ConfiguredBy, Id
Get-PowerBIReport -WorkspaceId $pbiWSId | Select-Object Name, Id, DatasetId
