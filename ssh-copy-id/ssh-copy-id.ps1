<#
 .NAME
    ssh-copy-id.ps1
 .SYNOPSIS
    Copy public key to remote hosts
 .DESCRIPTION
    See Synopsis
 .SYNTAX
    Invoke directly from the powershell command line
 .EXAMPLES
    .\Scriptname -i idtest.pub user@example.com password
    .\Scriptname -i idtest.pub user@example.com password -Debug
    .\ScriptName user@example.com password
.NOTES
    AUTHOR: VijayS
    DATE:   2014-01-23
    COMMENT: 
    DEPENDENCIES: 
        plink.exe
        type
 .HELPURL
    http://stackoverflow.com
 .SEEALSO
 .REFERENCE
    http://www.christowles.com/2011/06/how-to-ssh-from-powershell-using.html
#>

Param(
    [Parameter(Position=0,Mandatory=$true)]
    [String]$user_at_hostname,

    [Parameter(Position=1)]
    [String]$Password,

    [Parameter(HelpMessage="The public key file to copy")]
    [ValidateScript({Test-Path $_})]
    [Alias("i")]
    [String]$identity="id_rsa.pub",

    [switch]$ConnectOnceToAcceptHostKey=$false
    )

####################################
Function Get-SSHCommands {
 Param($Target,$Password, $CommandArray, $PlinkAndPath, $ConnectOnceToAcceptHostKey = $true)
 
 $plinkoptions = "`-ssh $Target"
 if ($Password) { $plinkoptions += " `-pw $Password " }
 
 #Build ssh Commands
 $CommandArray += "exit"
 $remoteCommand = ""
 $CommandArray | % {
  $remoteCommand += [string]::Format('{0}; ', $_)
 }
 
 #plist prompts to accept client host key. This section will
 #login and accept the host key then logout.
 if($ConnectOnceToAcceptHostKey)
 {
  $PlinkCommand  = [string]::Format("echo y | & '{0}' {1} exit",
   $PlinkAndPath, $plinkoptions )
  #Write-Host $PlinkCommand
  $msg = Invoke-Expression $PlinkCommand
 }
 
 #format plist command
 # $PlinkCommand = [string]::Format("'{0}' {1} '{2}'",
 #  $PlinkAndPath, $plinkoptions , $remoteCommand)
 $PlinkCommand = [string]::Format('{0} {1} "{2}"',
  $PlinkAndPath, $plinkoptions , $remoteCommand)
 
 #ready to run the following command
 #Write-Debug $PlinkCommand
 return "$PlinkCommand"
 #$msg = Invoke-Expression $PlinkCommand
 #$msg
}
##################
$ErrorActionPreference = "Stop" # "Continue" "SilentlyContinue" "Stop" "Inquire"
$DebugPreference = "Continue"
trap { Write-Error "ERROR: $_" } #Stop on all errors

$PlinkAndPath = '.\plink.exe'
 
#from http://serverfault.com/questions/224810/is-there-an-equivalent-to-ssh-copy-id-for-windows
$Commands = @()
$Commands += "umask 077" #change permissions to be restrictive
$Commands += "test -d .ssh || mkdir .ssh" #test and create .ssh director if it doesn't exist
$Commands += "cat >> .ssh/authorized_keys" #append the public key to file

#Write-Debug $Password
#Write-Debug $identity

Try {
    # test if files exist, trap will throw errors if they don't
    $tmp = Get-ItemProperty -Path $identity
    $tmp = Get-ItemProperty -Path $PlinkAndPath
    
    [String]$cmdline = Get-SSHCommands -Target $user_at_hostname `
     -Password $Password `
     -PlinkAndPath $PlinkAndPath `
     -CommandArray $Commands `
     -ConnectOnceToAcceptHostKey $ConnectOnceToAcceptHostKey

     # pipe the public key to the plink session to get it appended in the right place
     $cmdline = "& type ""$identity"" | " + $cmdline
     #$cmdline = Get-Content $identity | " + $cmdline
     Write-Debug $cmdline
     Invoke-Expression $cmdline
}
Catch {
    Write-Error "$($_.Exception.Message)"
}