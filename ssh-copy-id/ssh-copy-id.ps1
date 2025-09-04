<#
 .NAME
    ssh-copy-id.ps1
 .SYNOPSIS
    Copies a public SSH key to a remote host, intelligently finding the key file.
 .DESCRIPTION
    This script replicates the functionality of the Linux `ssh-copy-id` utility on Windows.
    It leverages the built-in OpenSSH client (ssh.exe) available in modern Windows versions (like Windows 11).

    The script will automatically search for the following public key files in your ~/.ssh/ directory, in this order:
    1. id_ed25519.pub
    2. id_ecdsa.pub
    3. id_rsa.pub

    You can also specify a particular key file using the -identity parameter.

    Note: While Windows 11 includes OpenSSH, it does not include the `ssh-copy-id` command itself.
    This script provides that missing convenience.
 .SYNTAX
    .\ssh-copy-id.ps1 -user_at_hostname <user@hostname> [-identity <path_to_public_key>]
 .EXAMPLES
    # Automatically find and copy the best available public key
    .\ssh-copy-id.ps1 -user_at_hostname user@example.com

    # Copy a specific public key
    .\ssh-copy-id.ps1 -user_at_hostname user@example.com -identity C:\Users\user\.ssh\my_other_key.pub
#>
Param(
    [Parameter(Mandatory=$true)]
    [String]$user_at_hostname,

    [Parameter(HelpMessage="Specify the public key file to copy. If not provided, the script will search for common key types.")]
    [ValidateScript({Test-Path $_})]
    [Alias("i")]
    [String]$identity
)

try {
    $publicKeyPath = $identity
    if (-not $publicKeyPath) {
        $sshDir = "$($env:USERPROFILE)\.ssh"
        $keyFiles = @("id_ed25519.pub", "id_ecdsa.pub", "id_rsa.pub")

        foreach ($keyFile in $keyFiles) {
            $potentialKey = Join-Path $sshDir $keyFile
            if (Test-Path $potentialKey) {
                $publicKeyPath = $potentialKey
                Write-Host "Found public key: $publicKeyPath"
                break
            }
        }
    }

    if (-not $publicKeyPath) {
        throw "No suitable public key found in ~/.ssh/ or specified with -identity. Please generate one using 'ssh-keygen'."
    }

    # Read the public key content
    $publicKey = Get-Content -Path $publicKeyPath -Raw

    # Command to execute on the remote server
    $remoteCommand = "umask 077; mkdir -p .ssh; echo `"$publicKey`" >> .ssh/authorized_keys; chmod 600 .ssh/authorized_keys"

    # Execute the command via ssh
    ssh $user_at_hostname $remoteCommand

    Write-Host "Public key copied successfully to $user_at_hostname"
}
catch {
    Write-Error "An error occurred: $_"
}
