
<#
Note this script uses start-job for parallelism.
It can likely be improved further with Powershell foreach parallelism (which uses workflows)

 This script enumerates all the Windows Active Directory groups in the specified top level OU's. 
 Note: this script only applies to Windows AD not Azure Active Directory (AAD)
For large OU's this script can take some time.

 For each group found in each top level OU
 1) It will list all the users and computers and any empty groups
 2) It will recursively enumerate the users and computers in each sub-group.
 3) If a user or computer is a member of multiple groups, it will list the user instance within each group
 4) It uses the global ctalog (port3268) so a user is 
 enumerated even if it is of a different root DC. Note that global catalog searches may 
 limit the properties available for an object
 5) The script avoids enumerating a group twice
 6) The script handles groups pointing to each other as follows. 
 - Groups are enumerated serially.
 - If G1 contains G2, app will enumerate G1 users, 
 and will enumerate G2 users
 - While enumerating users (which includes G1)
 , script wil see that G1 was already enumerated
 and skip the double enumeration.
#>

<#
   Recursively enumerates group members
   input: An AD group of type ADObject
   output: Adds found users to global CSV stream, 
   recursively loops through any group members
#>
function enumerateGroupMembers
{
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
        [ValidateNotNullorEmpty()]
        [Microsoft.ActiveDirectory.Management.ADObject] $currentGroup,
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [ValidateNotNullorEmpty()]
        [string] $GroupOU
        )
    
    #If we have already enumerated members for this group, exit the f(x)
    if ($GROUP_HASH.ContainsKey($currentGroup.DistinguishedName))
    {return;}

    #Add the group to hash table to keep track of groups enumerated
    $GROUP_HASH.Add($currentGroup.DistinguishedName, $null)

    #Obtain group members AD objects, note Global Catalog is being used (port 3268)
    $strLDAPFilter="(&(|(objectClass=group)(objectClass=user)(objectClass=computer))(memberof={0}))" -f $currentGroup.DistinguishedName
$timerQryMbrs.Start()
    $AllGroupMembers=get-adObject -LDAPFilter $strLDAPFilter -SearchBase ""  -Server "$GLOBALCATALOG`:3268" -SearchScope Subtree -ResultPageSize 1000 -ResultSetSize $null -Properties name,objectClass,mailNickname,mail,givenname,sn,telephoneNumber,mobile,objectSid,sAMAccountName,userAccountControl
$timerQryMbrs.Stop()
        
    #Add group to output list if its empty
    #using [void] instead of out-null for perf optimization
    if($AllGroupMembers.Count -eq 0 ){ 
$timerGrp.Start();
        [void]$MEMBER_CSVSTREAM.Append("`"")
        [void]$MEMBER_CSVSTREAM.Append(
            ( @($currentGroup.name,$currentGroup.objectClass,
                    $null,$null,
                    $null,$null,
                    $null,$null,
                    $null, $null,$GroupOU) -join "`",`"" ))
        [void]$MEMBER_CSVSTREAM.AppendLine("`"")
$timerGrp.Stop();
        return; #exit f(x) - group is empty
    }
    
    #recursively enumerate any child groups
    $AllGroupMembers |Where-Object {$_.ObjectClass -eq "group"}|
        foreach-object {enumerateGroupMembers ($_) ($GroupOU)}

    #collect user,computer members
    $usrMembers=$AllGroupMembers|
        Where-Object {$_.ObjectClass -ne "group"}

    $UsrCount=$usrMembers.Count #note this might be null or 0
    if(-not $UsrCount) { return; } #exit f(x) - no users to enumerate

$timerMbr.Start()
    #Gather member count for debug only
    $GROUP_HASH[$currentGroup.DistinguishedName]=$UsrCount

    #The remaining steps below will batch a set of users and spawn 
    #parallel threads to process each batch
    
    #calculate range size and number of threads per batch
    [int]$BatchSize=0;
    [int]$currRangeEnd=0;
    if($UsrCount -le 200) {$BatchSize=$MINBATCHSIZE} #smallest batch size
    else{$BatchSize=($UsrCount/$NUMPROCS)}#spawn numprocs parallel jobs

    #declare array of parallel jobs
    $jobs=@()
    
    #Loop through each member and split processing into parallel batches
    #do not bother to spawn parallel threads if small set of members
    #just enumerate the members and add to the csv stream
    #note [void] instead of out-null optimization, also note for loop optimization
    for($currRangeStart=0;$currRangeStart -lt $UsrCount;$currRangeStart=$currRangeEnd)
    {
        #calculate batch end point
        $currRangeEnd=$currRangeStart+$BatchSize
        
        #ensure batch end point does not exceed total array size
        if($currRangeEnd -gt $UsrCount) {$currRangeEnd=$UsrCount}

        #calculate actual batch size based on adjustment above
        $currRangeSz=$currRangeEnd-$currRangeStart

        #Process batch serially if small enough
        if($currRangeSz -lt $MINBATCHSIZE) #avoid spawning an expensive job for small sets of data
        {
            for($k=$currRangeStart;$k -lt $currRangeEnd;$k++)
            {
                $logonString=$null
                $IsAccountDisabled=[int]([bool] ($usrMembers[$k].userAccountControl -BAND $ACCOUNTDISABLE_FLAG))
                $objSid=$usrMembers[$k].objectSid #this should already be of type SecurityIdentifier,but could be string
                if($objSid){
                    if($objSid.GetType().Name -ne "SecurityIdentifier"){
                        $objSid = new-object System.Security.Principal.SecurityIdentifier($objSid) #convert SecurityIdentifier obj
                    }
                    try{
                        $logonString = ($objSid.Translate([Security.Principal.NTAccount])).ToString()#get domain\username syntax
                    }catch{
                        $logonString= [string]::concat("NOTFOUND_TRANSLATE\",$usrMembers[$k].sAMAccountName)
                        writelog($Error[0].Exception)
                        writelog($Error[0].ScriptStackTrace)
                    }
                }else{$logonString= [string]::concat("NOTFOUND_OBJSID\",$usrMembers[$k].sAMAccountName)}

                #Add user to global CSV stream
                [void]$MEMBER_CSVSTREAM.Append("`"")
                [void]$MEMBER_CSVSTREAM.Append((@($currentGroup.name,
                            $usrMembers[$k].objectClass,
                            $logonString, 
                            $usrMembers[$k].mailNickname,
                            $usrMembers[$k].mail,
                            $usrMembers[$k].givenname,
                            $usrMembers[$k].sn,
                            $usrMembers[$k].telephoneNumber,
                            $usrMembers[$k].mobile,
                            $IsAccountDisabled,
                            $GroupOU) -join "`",`""))
                [void]$MEMBER_CSVSTREAM.AppendLine("`"")
            }
        }else{
            #spawn a parallel process for large enough batch
            $jobs+=Start-Job {
                param($GroupName,$GroupOU,$currRangeSz,$usrSubset)
                #declare fixed size array
                $currBatchArr=new-object string[] ($currRangeSz)
                #loop through batch of users and 
                #build new array which contains manipulated strings
                for($k=0;$k -lt $currRangeSz;$k++){
                    $logonString=$null
                    $IsAccountDisabled=[int]([bool] ($usrSubset[$k].userAccountControl -BAND $ACCOUNTDISABLE_FLAG))
                    $objSid=$usrSubset[$k].objectSid #this should already be of type SecurityIdentifier,but could be string
                    if($objSid){
                        if($objSid.GetType().Name -ne "SecurityIdentifier"){
                            $objSid = new-object System.Security.Principal.SecurityIdentifier($objSid) #convert SecurityIdentifier obj
                        }
                        try{
                            $logonString = ($objSid.Translate([Security.Principal.NTAccount])).ToString()#get domain\username syntax
                        }catch{
                            $logonString= [string]::concat("NOTFOUND_TRANSLATE\",$usrSubset[$k].sAMAccountName)
                            writelog($Error[0].Exception)
                            writelog($Error[0].ScriptStackTrace)
                        }
                    }else{$logonString= [string]::concat("NOTFOUND_OBJSID\",$usrSubset[$k].sAMAccountName)}

                    $currBatchArr[$k]= [string]::Concat("`"",
                        (@($GroupName,
                            $usrSubset[$k].objectClass,
                            $logonString,
                            $usrSubset[$k].mailNickname,
                            $usrSubset[$k].mail,
                            $usrSubset[$k].givenname,
                            $usrSubset[$k].sn,
                            $usrSubset[$k].telephoneNumber,
                            $usrSubset[$k].mobile,
                            $IsAccountDisabled,
                            $GroupOU) -join "`",`""),
                        "`"")
                }#end foreach parallel subset array element
                return $currBatchArr
            } -ArgumentList ($currentGroup.name),$GroupOU, $currRangeSz, ($usrMembers[$currRangeStart..$currRangeEnd])
        }#end if-else small range
    }#end foreach member loop
        
    if($jobs)
    {
        [void] ($jobs |wait-job)
        #collect job results
        $res=$jobs|Receive-Job
        #append output of each job to global csv stream
        $res |foreach {[void] $MEMBER_CSVSTREAM.AppendLine($_);}
        #delete parallel jobs
        $jobs | Remove-Job
    }
$timerMbr.Stop()
}


#import the active directory powershell module, this is needed in order to use the 
#newer and more efficient AD commandlets
import-module activedirectory

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


#Script starts here
cls

#declare debug timers
$timerMbr=new-object System.Diagnostics.Stopwatch
$timerGrp=new-object System.Diagnostics.Stopwatch
$timerTL=new-object System.Diagnostics.Stopwatch
$timerQryMbrs=new-object System.Diagnostics.Stopwatch

[int] $MINBATCHSIZE=25
# set to number of processors on the machine where the script will run
# Use 8 by default, this will dictate how many parallel threads to spawn
[int] $NUMPROCS =8 
[int] $ACCOUNTDISABLE_FLAG=0x0002 #see support.microsoft.com/kb/305144

#Instead of using default GC, for example Get-ADDomainController  -Discover -DomainName "contoso.com" -Service GlobalCatalog
#put infrastructure in place to allow choosing a preferred GC should one be found to be more optimal
$GLOBALCATALOGs=Get-ADDomainController -Filter {isGlobalCatalog -eq "true" -and Enabled -eq "true"} |
    where-object{($_.HostName -like "<<NAME OF YOUR DOMAIN GLOBAL CATALOG/DOMAIN CONTROLLER HERE>>*")}
$GLOBALCATALOG=$GLOBALCATALOGs | Select-Object -ExpandProperty HostName  -First 1
if(-not $GLOBALCATALOG){
    writelog("Severe Error: a global catalog for AD object queries was not found.Exiting script.");
    exit -1;
}else{writelog("Using the following global catalog: $GLOBALCATALOG")}

writelog("Script started: " + (get-date))
#Top level OU's we are interested in enumerating
$RootOU_LDAPQueryArr =@("OU=Production,DC=contoso,DC=com",
        "OU=Development,DC=contoso,DC=com")

#Create global dictionary object which uses tress for fast insert and binary search. Purpose is to avoid enumerating groups twice.
$GROUP_HASH=new-object 'System.Collections.Generic.SortedDictionary[string,int]'  -ArgumentList ([System.StringComparer]::CurrentCultureIgnoreCase) 

#Create global csv memory stream because it is 
#faster to write to file in one large bulk operation instead of line by line
$MEMBER_CSVSTREAM=new-object System.Text.StringBuilder(50000000) #set intial large size to avoid dynamic growth slowness

#Define the output csv file and  headers
$OUTFILE = "ADGroupMembersList.csv" #output file name, will be dumped in local working directory
$HDR= @("Host Group Name","Member Type","Member logon Account","Member Exchange Alias","Member SMTP","First Name","Last Name","Office Phone","Mobile","IsDisabled","GroupOU")

#write header to CSV stream
[void] $MEMBER_CSVSTREAM.AppendLine(("`""+($HDR -join "`",`"")+"`""))


#Loop through the desired root OU's and enumerate root groups
foreach ( $rootOU_LDAPQuery in $RootOU_LDAPQueryArr) 
{
    $RootGroupArr=Get-ADObject -LDAPFilter "(ObjectClass=group)" -SearchBase $rootOU_LDAPQuery -SearchScope Subtree -ResultPageSize 1000 -ResultSetSize $null 
        
    #Collect count of number of groups found
    Writelog ("Number of groups found in Root OU: $rootOU_LDAPQuery ="+$RootGroupArr.count)
    
    #Extract user-friendly root OU name
    $strOU=$rootOU_LDAPQuery.Split(",")|where-object {$_.Contains("OU=")}|ForEach-Object {$_.Replace("OU=","")}|select-object -First 1
    
    #Enumerate all the members which are part of the root OU groups
    $timerTL.Start()
        $RootGroupArr |foreach-object {enumerateGroupMembers ($_) ($strOU)}
    $timerTL.Stop()
}#end foreach rootOU

writelog ("Total groups and sub-groups enumerated: " + $GROUP_HASH.Count)
writelog ("Top groups with most users:")
$GROUP_HASH.GetEnumerator() | Sort-Object Value -Descending |
    Select-Object @{Name="Group Name";
        Expression={$_.Key.Substring(3,$_.Key.IndexOf(",")-3)}},
    @{Name="Number Of Members";
        Expression={$_.Value}} -First 10

writelog(("Total script duration H/M/sec/ms:{0:00}:{1:00}:{2:00}:{3:00}" -f $timerTL.Elapsed.Hours,$timerTL.Elapsed.Minutes,$timerTL.Elapsed.Seconds,$timerTL.Elapsed.Milliseconds))
writelog(("Time spent processing groups locally H/M/sec/ms:{0:00}:{1:00}:{2:00}:{3:00}" -f $timerGrp.Elapsed.Hours,$timerGrp.Elapsed.Minutes,$timerGrp.Elapsed.Seconds,$timerGrp.Elapsed.Milliseconds))
writelog(("Time spent querying AD for members H/M/sec/ms:{0:00}:{1:00}:{2:00}:{3:00}" -f $timerQryMbrs.Elapsed.Hours,$timerQryMbrs.Elapsed.Minutes,$timerQryMbrs.Elapsed.Seconds,$timerQryMbrs.Elapsed.Milliseconds))
writelog(("Time spent processing members locally H/M/sec/ms:{0:00}:{1:00}:{2:00}:{3:00}" -f $timerMbr.Elapsed.Hours,$timerMbr.Elapsed.Minutes,$timerMbr.Elapsed.Seconds,$timerMbr.Elapsed.Milliseconds))

#write to csv file
$timerTL.Restart()
$stream= new-object System.IO.StreamWriter($OUTFILE,$false,[System.Text.Encoding]::ASCII)
$stream.WriteLine($MEMBER_CSVSTREAM.ToString())
$stream.Close()
$timerTL.Stop()
writelog(("Time spent writing CSV file H/M/sec/ms:{0:00}:{1:00}:{2:00}:{3:00}" -f $timerTL.Elapsed.Hours,$timerTL.Elapsed.Minutes,$timerTL.Elapsed.Seconds,$timerTL.Elapsed.Milliseconds))
writelog("Script completed: " + (get-date))