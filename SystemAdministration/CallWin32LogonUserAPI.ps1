<#
Call Win32 LogonUser API through Powershell
#>
Set-ExecutionPolicy RemoteSigned

$functionSignature = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);
'@

$LogonW32APIType=Add-Type -Name LogonW32API -MemberDefinition $functionSignature -passThru

$domain=Read-Host 'What is the account domain?'
$acct=Read-Host 'What is the account name?'
$pass = Read-Host 'What is the account password?' -AsSecureString
$convertedPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))

[System.IntPtr]$userToken = [System.IntPtr]::Zero
$success = $LogonW32APIType::LogonUser($acct,    # UserName
                                        $domain, # Domain
                                        $convertedPass, #Password
                                        3, #LOGON32_LOGON_NETWORK 
                                        0, # LOGON32_PROVIDER_DEFAULT
                                        [ref]$userToken) 
([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())
if ($success)
{
    Write-Host 'Execute API LogonUser: status: SUCCEEDED.'
    Write-Host 'Dumping out Windows Identity details:'
    $id=$null
    $id=new-object System.Security.Principal.WindowsIdentity($userToken)
    ([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())
    $id
} else
{
 Write-Host 'Execute API LogonUser: status: FAILED.'
}


#LOGON32_PROVIDER_DEFAULT = 0,
#LOGON32_LOGON_INTERACTIVE = 2,
#LOGON32_LOGON_NETWORK = 3,
#LOGON32_LOGON_BATCH = 4,
#LOGON32_LOGON_SERVICE = 5,
#LOGON32_LOGON_UNLOCK = 7,
#LOGON32_LOGON_NETWORK_CLEARTEXT = 8,
#LOGON32_LOGON_NEW_CREDENTIALS = 9
#[Advapi32.LogonW32API]
