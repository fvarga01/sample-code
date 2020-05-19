<# The script below retrieves the Azure Activity Logs programmatically
Use of the REST API (Method2) requires creating an Azure Active Directory (AAD) application
 which is then used to acquire a bearer token

View and retrieve Azure Activity log events https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/azure-monitor/platform/activity-log-view.md
Activity Log event's JSON Schema https://docs.microsoft.com/en-us/azure/azure-monitor/platform/activity-log-schema
#>
$subscriptionName = ''
$subscriptionId = ''
$pwd = '<<AAD app password value>>'
$azAppADName = '<<AAD app name>>'
$outputfile =  [string]::Concat( 
    @("AzureActivityLogs",
     (get-date -Format 'yyyyMMdd').ToString(),
     ".csv") )
<#####################################################################
#####################################################################
## METHOD 1: Via PowerShell Commandlet
https://docs.microsoft.com/en-us/azure/azure-monitor/platform/activity-log-view#powershell
https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/view-activity-logs
#####################################################################
#####################################################################>
#region Method1

#Connect to your Azure subscription
Connect-AzAccount -Subscription $subscriptionName
#verify your subscription context
get-azcontext

#Additional commandlet parameters
# -ResourceProvider 'Microsoft.Sql'
# -StartTime 2020-05-14T01:00
# -EndTime 2020-05-15T23:00
# -MaxRecord 100000
# -ResourceGroupName test-rg1 

#Get the activity log records for delete actions as of 2 days ago
#and filter out the databricks management groups which can have multiple delete activities
#records are sorted by resourcegroup name
#You may need to increase MaxRecord number to ensure all records are collected
#https://docs.microsoft.com/en-us/powershell/module/az.monitor/get-azlog?view=azps-3.8.0
$logs = Get-AzLog -Status Succeeded -StartTime (Get-Date).AddDays(-2)  -MaxRecord 1000 |
    Where-Object {$_.Authorization.Action -like '*/delete' -and $_.ResourceGroupName -notlike "databricks-rg-*"}  |
    Select-Object ResourceGroupName, EventTimestamp, @{n="Action";e={$_.Authorization.Action}}, ResourceId |
    Sort-Object ResourceGroupName
#display results as a table
$logs | format-table -AutoSize -Wrap -Force
#export results to a csv file
$logs | Select-Object * | export-csv -Path $outputfile
#endregion Method1

#####################################################################
#####################################################################
## METHOD 2: Via REST API
#Azure Monitor REST API Walkthrough https://docs.microsoft.com/en-us/azure/azure-monitor/platform/rest-api-walkthrough
#Azure Monitor REST API filter syntax https://docs.microsoft.com/en-us/rest/api/monitor/filter-syntax
#####################################################################
#####################################################################
#region Method2
# Authenticate to a specific Azure subscription.
Connect-AzAccount -SubscriptionId $subscriptionId
#verify your subscription context
get-azcontext
####################################################################
##### Part1: Create a service principal in Azure Active Directory ##
###      ***You only need to run this one time***
####################################################################
# This will be used to obtain a REST API authentication (Bearer) token
#region Method2-Part1
# Password for the service principal
$secureStringPassword = ConvertTo-SecureString -String $pwd -AsPlainText -Force

# Create a new Azure AD application - this 
$azureAdApplication = New-AzADApplication `
                        -DisplayName $azAppADName `
                        -HomePage "https://localhost/$azAppADName" `
                        -IdentifierUris "https://localhost/$azAppADName" `
                        -Password $secureStringPassword

# Create a new service principal associated with the designated application
New-AzADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId

# Assign Reader role to the newly created service principal
New-AzRoleAssignment -RoleDefinitionName Reader `
                          -ServicePrincipalName $azureAdApplication.ApplicationId.Guid
#endregion Method2-Part1
####################################################################
##### Part2: Use the previously created AAD service principal 
##### to obtain a REST API BEARER token
####################################################################
#region Method2Part2
$azureAdApplication = Get-AzADApplication -IdentifierUri "https://localhost/$azAppADName"
$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
$clientId = $azureAdApplication.ApplicationId.Guid
$tenantId = $subscription.TenantId
$authUrl = "https://login.microsoftonline.com/${tenantId}"
$AuthContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]$authUrl
$cred = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential -ArgumentList ($clientId, $pwd)
$result = $AuthContext.AcquireTokenAsync("https://management.core.windows.net/", $cred).GetAwaiter().GetResult()
# Build an array of HTTP header values
$authHeader = @{
    'Content-Type'='application/json'
    'Accept'='application/json'
    'Authorization'=$result.CreateAuthorizationHeader()
}
#DEBUG:"Bearer " + $result.AccessToken | out-file bearer.txt -Append
#endregion Method2Part2

####################################################################
##### Part3: Call the REST API using the BEARER token
####################################################################
#region Method2Part3
Clear-Host #clear the screen
#$filter = "eventTimestamp ge '2020-05-14' and eventTimestamp le '2020-05-16'"
$filter = "eventTimestamp ge '2020-05-10' and status eq 'Succeeded'" # and eventChannels eq 'Admin, Operation'"
$selectList= "caller, resourceGroupName, operationName,eventTimestamp,resourceId"
$apiVersion = "2015-04-01"
$request = "https://management.azure.com/subscriptions/"+
    $subscriptionId+
    "/providers/microsoft.insights/eventtypes/management/values?api-version=${apiVersion}&`$filter=${filter}&`$select=${selectList}"
    #"/providers/microsoft.insights/eventtypes/management/values?api-version=${apiVersion}&`$filter=${filter}"

#Use ArrayList instead of an array when adding large amount of log entries
$alllogs_xlarge=[System.Collections.ArrayList]::new()
$currPageLogs = @()
do{
    $logs = Invoke-RestMethod -Uri $request `
        -Headers $authHeader `
        -Method Get `
    #-Verbose
    $currPageLogs = $logs.value | 
        where-object { 
            $_.resourceGroupName -and $_.resourceGroupName -notlike "databricks-rg-*" -and
            $_.operationName.value -like "*/delete*"} |
            Select-Object caller, resourceGroupName, @{n='operationName';e={$_.operationName.value}}, eventTimestamp,resourceId
    

    #$currPageLogs | ForEach-Object{[void] $alllogs_xlarge.Add($_)}
    [void] $alllogs_xlarge.Add($currPageLogs) #note that each entry added to the ArrayList is itself an array in this case
            #https://docs.microsoft.com/en-us/dotnet/api/system.collections.arraylist.add?view=netcore-3.1
            #https://docs.microsoft.com/en-us/dotnet/api/system.collections.arraylist.addrange?view=netcore-3.1
    $request = $logs.nextLink #page through additional logs using the provided nextLink value
} while ($request)

#Write the log entries to a CSV file
#Specifying the SyncRoot property which conveniently flattens the multidimensional array into a single dimension array in the process
$alllogs_xlarge | Select-Object -ExpandProperty SyncRoot | Export-Csv -Path $outputfile
#($alllogs_xlarge | Select-Object -ExpandProperty SyncRoot).GetType()

#endregion Method2

