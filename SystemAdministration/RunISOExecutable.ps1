# These code snippets demonstrate how to run an ISO excutable
# The code will not run as is because I've removed some of the utility functions,
# such as writelog, read params from config file, workflows, etc.
# Purpose of my sharing is to show overall approach which was used for running ISO/EXE files

$EXENAME="setup.exe"

    <# ---------------------------------
    runExe: Run an executable with the supplied arguments.
    Note currently we check for lower case string match pattern.
    --------------------------------- #>
    function runExe()
    {
        param( 
        [Parameter(Mandatory=$true)]
        [ValidatePattern("\.(?i)(exe)$")] #verify an exe file is supplied
        [ValidateScript ({[System.IO.File]::Exists($_)})] #Verify file is accessible
        [string] $ExeOrISOFile,
    
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string] $ExeArgs,

        [Parameter(Mandatory=$false)]
        [string] $ExeLogFileFilter
         )

        if($RUNMODE -ne "PRODUCTION"){
            writelog ("******* TEST MODE ****** $ExeOrISOFile") -logType DEBUG
            return 1
        }
        writelog ("******* PRODUCTION MODE ****** $ExeOrISOFile") -logType DEBUG

        try{
            unblock-file  $ExeOrISOFile -ErrorAction SilentlyContinue
            $ret=start-process -FilePath "$ExeOrISOFile" -Wait -PassThru -ArgumentList "$ExeArgs" -Verb RunAs
            if(-not $ret){
                throw new-object System.Exception ("Process did not run: $ExeOrISOFile")
            }elseif( $ret.HasExited -and (($ret.ExitCode -eq 0) -or ($LastExitCode -eq 0))){
                WriteLog "Process completed succesfully."
            }elseif($ret.HasExited -and (($ret.ExitCode -eq 3010) -or ($LastExitCode -eq 3010))) {
                WriteLog("Process completed succesfully but a reboot is required. Rebooting now.")
                <# relies on PS Workflow
                *** Restart-Computer -Force -Confirm:$false
                Suspend-Job -Name $STRJOB
                writelog "Continuing after reboot."
                ***#>
            }else{ 
                WriteLog ("Process returned a non-zero value.") -logType ERROR
                throw new-object System.Exception ("Error: Process $ExeOrISOFile returned non-zero status. Review log file. Subsequent commands will not run.")
            }
            writelog ("Process LastExitCode: $LastExitCode , Return code: " + $ret.ExitCode) -logType DEBUG
            CollectExeLogs $ExeLogFileFilter
            return $ret
            }
        catch{
            WriteLog ("Process LastExitCode: $LastExitCode,  HasExited: " + $ret.HasExited  + ", Return code: " + $ret.ExitCode ) -logType DEBUG
            CollectExeLogs $ExeLogFileFilter
            throw #re-throw the exception so parent can stop processing additional sequential commands
            }
    }

    <# ---------------------------------
    runISO: Mounts the ISO file as a volume, and runs the executable 
    from the volume path.

    If the file is already mounted, then the cmdlet will 
    display the following error (you will need to manually dismount the iso
    file to continue):
        "The process cannot access the file because it is 
        being used by another process."
    --------------------------------- #>
    function runISO()
    {
        param( 
        [Parameter(Mandatory=$true)]
        [ValidatePattern("\.(?i)(iso)$")] #verify an iso file is supplied
        [ValidateScript ({[System.IO.File]::Exists($_)})] #Verify path is accessible
        [string] $IsoFile,
    
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()] #allow empty string args, however Args may not be omitted in config file, so mandatory is true
        [string] $ExeArgs,

        [Parameter(Mandatory=$false)] #ExeLogFileFilter may be omitted in config file
        [string] $ExeLogFileFilter,

        [Parameter(Mandatory=$true)]
        [ValidatePattern("\.(?i)(exe)$")] #verify an exe file is supplied - not enclosed in double quotes
        [string] $MountedExe
        )

        unblock-file  $IsoFile -ErrorAction SilentlyContinue
        #Mount the iso as a local volume:
        $vol= Mount-DiskImage -ImagePath $IsoFile -PassThru | get-DiskImage | Get-Volume 
    
        if($null -ne $vol) {
            $MountedExeFullName=join-path ($vol.DriveLetter+":") -ChildPath $MountedExe
            runExe $MountedExeFullName $ExeArgs $ExeLogFileFilter
            Start-Sleep 5 #give about 5 seconds to ensure executable is fully stopped before attempting to dismount
            Dismount-DiskImage -ImagePath $IsoFile
        }#end if
        else {
            throw new-object System.Exception( "RunIso: Failed  to mount iso file." + $IsoFile )
        }
    }

    <# ---------------------------------
    RunCommand: Run one sequenced command.
    --------------------------------- #>
    function RunCommand()
    {
        param( 
            [Parameter(Mandatory=$true)]
            [ValidateNotNull()]
            [PSObject] $CommandToRun
        )
        $searchStr=$CommandToRun.ExeOrISOFile

        switch -regex ("$searchStr")
        {
                "\.(?i)(iso)$" {
                        runISO ($CommandToRun.ExeOrISOFile) ($CommandToRun.ExeArgs) ($CommandToRun.ExeLogFileFilter) ($EXENAME)
                        break;
                }
                "\.(?i)(exe)$" {
                        runExe  ($CommandToRun.ExeOrISOFile) ($CommandToRun.ExeArgs) ($CommandToRun.ExeLogFileFilter)
                        break;
                }
                default {
                    throw [System.Exception] "Expected EXE or ISO extension."
                    break;
                }
            }
    }
