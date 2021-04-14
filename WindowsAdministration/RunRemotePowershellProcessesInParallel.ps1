# These code snippets demonstrate how to run remote powershell
#  processes on various remote servers in parallel
# The remote script you wish to run (MyRemotePSScript.ps1 in this example)
# should reside on a UNC share which is accessbile by each of the remote Windows servers
#
# The code will not run as is because I've removed some of the utility functions,
# such as writelog, read params from config file, etc.
# Purpose of my sharing is to show overall approach which was used for
# enabling delegation and remote execution

<# Enable delegation settings
    #This is needed in order to access UNC share 
    #from remote session using delegated AD account credentials
#>
function prepDelegationPermissions
{
    #Step1: Client (machine from which script is initiated)
    #provides a list of the remote servers which can delegate its credentials
    Enable-WSManCredSSP -role client -DelegateComputer $SERVERLIST -force | out-null
    
    #Step2: Server specifies it can delegate, this section changes the delegation properties on each of the remote servers
    #Invoke-Command -ComputerName $SERVERLIST -ScriptBlock{Enable-WSManCredSSP -role server -Force} | out-null
    foreach( $svr in $SERVERLIST)
    {
        Connect-WSMan $svr
        Set-Item WSMan:\$svr\Service\Auth\CredSSP -Value $true
    }

    
}

<#
 Create remote DCOM sessions
 DCOM session are less restricted, so will create DCOM session first to remotely enable CredSSP sessions
#>
function createDCOMCimSessions{
#--Delegation step 2: Create remote DCOM sessions
    #DCOM session are less restricted, so will create DCOM session first to remotely enable CredSSP sessions
    $protocol=New-CimSessionOption -Protocol DCOM
        #WSMAN: -computername requires uri param on w2008 machine."Err A DMTF resource URI was used to access a non-DMTF class"
        #DCOM: new-cimsession +credssp errcode 8 not enough storage on both w2008 and 2012.
    $DCOMSESSIONS= New-CimSession -ComputerName $SERVERLIST -Credential $cr -SessionOption $protocol
    if(-not $DCOMSESSIONS){
        throw new-object System.Exception ("Unable to create DCOM session for any servers. Exiting program.")
    }else{
        $MissingDCOMSessions=Compare-Object -ReferenceObject $DCOMSESSIONS.ComputerName -DifferenceObject $SERVERLIST -PassThru
        if($MissingDCOMSessions){
            writelog "The following DCOM session where not created:" -strArray $MissingDCOMSessions  -logType WARNING
        }
    }
}

<#
Use DCOM sessions to enable CredSSP remotely
#>
function prepDelegationAndExecutionPermissionsViaDCOMCim
{
    createDCOMCimSessions

    #--Delegation step 3: Use DCOM sessions to enable CredSSP remotely
    #opt1 through Windows job scheduler: $dcomProcesses=Invoke-CimMethod -CimSession $DCOMSESSIONS -ClassName  WIN32_Process -MethodName Create -Arguments @{CommandLine="powershell.exe -Command Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Confirm:$false -Scope CurrentUser -Force;Enable-PSRemoting -Force;Enable-WSManCredSSP -role server -Force;$a=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-Command Enable-WSManCredSSP -role server -Force';$tsk=Register-ScheduledTask -TaskName contosoEnablePSDelegation -Action $a -User 'NT AUTHORITY\SYSTEM' -RunLevel Highest;$tsk=Get-ScheduledTask -TaskName contosoEnablePSDelegation;start-sleep 5;Start-ScheduledTask -InputObject $tsk;start-sleep 5;Unregister-ScheduledTask -TaskName contosoEnablePSDelegation -Confirm:$false;"} -Confirm:$false
    $dcomProcesses=Invoke-CimMethod -CimSession $DCOMSESSIONS -ClassName WIN32_Process `
        -MethodName Create -Arguments `
        @{CommandLine="powershell.exe -Command Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force;Enable-PSRemoting -Force;Enable-WSManCredSSP -role server -Force;"} `
        -OperationTimeoutSec 30 
    if($dcomProcesses){
        #***Give enough time for tasks which enable CredSSP to complete
        start-sleep 30
        #***Remove DCOM sessions
        Get-CimSession | Remove-CimSession
    }

}

<#
Create CredSSP (delegated) sessions
#>
function createCredSSPCimSessions{

        #--Delegation step 4:Create CredSSP (delegated) sessions
        [void] ($CREDSSPSESSIONS= New-CimSession -ComputerName $SERVERLIST -Credential $cr -Authentication CredSsp);
        if(-not $CREDSSPSESSIONS){
                throw new-object System.Exception ("Unable to create CredSSP sessions for any servers. Exiting Program.");
        }else{
            $failedCredSSP=Compare-Object -ReferenceObject $CREDSSPSESSIONS.ComputerName -DifferenceObject $SERVERLIST -PassThru
            if($failedCredSSP){
                writelog "The following CredSSP sessions were not created:" -logType ERROR -strArray $failedCredSSP}
        }
}

<#
  Run script on remote servers using CredSSP sessions
#>
function RunRemotePSInParallelViaCimSession
{
   
    #First Unblock script via remote delegated session
    #Policies on remote computer might block running .ps1 scripts from UNC share.
    #This requires CredSSP session because scripts are on UNC share, requires delegation
    $credsspProcesses=Invoke-CimMethod -CimSession $CREDSSPSESSIONS -ClassName Win32_Process `
        -MethodName Create -Arguments `
        @{CurrentDirectory=$CENTRALSHARE;CommandLine="powershell.exe -Command unblock-file MyRemotePSScript.ps1"} `
        -Confirm:$false;
    if($credsspProcesses) {
        start-sleep 5;}#give some time for file unblock to complete

    writelog "Starting remote processes." -logType DEBUG
    $credsspProcesses=Invoke-CimMethod -CimSession $CREDSSPSESSIONS -ClassName Win32_Process `
        -OperationTimeoutSec 200 -MethodName Create -Arguments `
        @{CurrentDirectory=$CENTRALSHARE;CommandLine="powershell.exe -file MyRemotePSScript.ps1 $PARAM1";}
    if(-not $credsspProcesses){
            throw new-object System.Exception ("Unable to start remote processes for any servers. Exiting Program.");
    }else{
        $failedToStartProcesses=Compare-Object -ReferenceObject $credsspProcesses.PSComputerName `
            -DifferenceObject $SERVERLIST -PassThru
        if($failedToStartProcesses){
            writelog "The following remote processes were not started:" -logType ERROR `
                -strArray $failedToStartProcesses
        }
        #*** Display status of each remote process
        ReportCimProcessStatus $credsspProcesses
    }
}
<#
    Show status of currently running remote CIM processes
#>
function ReportCimProcessStatus
{
    param( 
        [ValidateNotNull()]
        [PSObject[]] $cimProcesses
    )

    do{
        [PSObject[]]$stillRunningProcesses=$null
        foreach ($p in $cimProcesses)
        {
            $filter="Name='powershell.exe' and ProcessId='" + $p.ProcessId+ "'" 
            $cimsess = Get-CimSession -ComputerName ($p.PSComputerName)
            $stillRunningProcesses+=Get-CimInstance  -CimSession $cimSess -ClassName Win32_Process -Filter $filter|
                Select-Object CSName, ProcessName, ProcessId, ThreadCount, UserModeTime, WorkingSetSize, CreationDate
        }
        if($stillRunningProcesses){
            writelog "Status of running processes: " -logType DEBUG -strArray  $stillRunningProcesses
            start-sleep 30
        }
    }while($stillRunningProcesses)
}

<#
 Create PSSESSIONs for each of the servers in the SERVERLIST
#>
function createPSSessions{

    #Create remote sessions based on the array of servernames to test:
    $PSSESSIONS=New-PSSession $SERVERLIST    -Credential $cr -Authentication Credssp
    # name each remote session (for easier debugging):
    foreach( $individualSess in $PSSESSIONS )
    {
        $individualSess.Name=("RemoteSess_" + $individualSess.ComputerName)
        write-output ($individualSess.Name +": "+ $individualSess.State)
    }
  
  }

<#
    - For each remote server, set the proper remote script execution policy
    - Also, if the script file was downloaded or emailed, windows may mark the file as blocked, you should unblock the script files or they may fail to run
#>
function prepExecutionPermissionsViaPSSession
{

    #Set powershell execution policy on the remote servers to allow remote scripts to execute
    Invoke-Command -Session $PSSESSIONS -ScriptBlock{Set-ExecutionPolicy -ExecutionPolicy RemoteSigned}

    #Unblock powershell scripts - downloaded scripts are blocked by default
    Invoke-Command -Session $PSSESSIONS -ScriptBlock{param([string] $CENTRALSHARE2) unblock-file  "$CENTRALSHARE2\MyRemotePSScript.ps1"} -ArgumentList $CENTRALSHARE
}

<#
 Run a PowerShell Script remotely and sequentially using a PSSESSION
#>
function RunRemotePSSequentiallyViaPSSession
{
    Invoke-Command -Session $PSSESSIONS -Scriptblock {param([string]$PARAM2) &"$CENTRALSHARE2\MyRemotePSScript.ps1" $PARAM2} -ArgumentList $PARAM
}

######################### MAIN #################

try{
    #***Global initializations
    $REMOTESCRIPTACCOUNT = "contoso\admin1"
    $CENTRALSHARE = "\\uncserver1\share1"
    [String []] $SERVERLIST=@()
    $DCOMSESSIONS=@()
    $CREDSSPSESSIONS=@()
    $PSSESSIONS=@()

    #***Enter credentials used to run scripts on remote computers
    $cr=Get-Credential -Message `
        "Enter credentials for account $REMOTESCRIPTACCOUNT.`nThis account will be used to run the remote powershell sessions." `
        -UserName $REMOTESCRIPTACCOUNT

    $SERVERLIST = @() 
    prepDelegationPermissions

    #sequential via PSSession
    createPSSessions
    prepExecutionPermissionsViaPSSession
    RunRemotePSSequentiallyViaPSSession

    #Parallel via CimSession
    
    prepDelegationAndExecutionPermissionsViaDCOMCim
    createCredSSPCimSessions
    RunRemotePSInParallelViaCimSession #This will also show the status of each process until they've all completed

}catch [System.Exception]{ 
    writelog $_.Exception.Message -logType ERROR
}finally{
    Get-CimSession |Remove-CimSession
    Get-PSSession  | Remove-PSSession
}