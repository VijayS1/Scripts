<#
 .NAME
    ssh-copy-id.ps1
 .SYNOPSIS
    Safely copies a public SSH key to a remote host, checking for existing keys first.
 .DESCRIPTION
    This script replicates the functionality of the Linux `ssh-copy-id` utility on Windows.
    It first checks if the key already exists on the remote server and will not add a duplicate.
    If the copy operation fails, it attempts to diagnose common server-side permission issues.
 .PARAMETER user_at_hostname
    The user and hostname to connect to (e.g., user@example.com).
 .PARAMETER identity
    The path to a specific public key file to copy.
 .EXAMPLE
    # Safely copy the best available public key
    .\ssh-copy-id.ps1 -user_at_hostname user@example.com

 .EXAMPLE
    # Copy a specific key and see verbose output
    .\ssh-copy-id.ps1 -user_at_hostname user@example.com -identity C:\Users\user\.ssh\my_key.pub -Verbose
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String]$user_at_hostname,

    [Parameter(HelpMessage="Specify the public key file to copy. If not provided, the script will search for common key types.")]
    [ValidateScript({Test-Path $_})]
    [Alias("i")]
    [String]$identity
)

$publicKeyPath = $identity
if (-not $publicKeyPath) {
    $sshDir = "$($env:USERPROFILE)\.ssh"
    $keyFiles = @("id_ed25519.pub", "id_ecdsa.pub", "id_rsa.pub")

    foreach ($keyFile in $keyFiles) {
        $potentialKey = Join-Path $sshDir $keyFile
        if (Test-Path $potentialKey) {
            $publicKeyPath = $potentialKey
            Write-Verbose "Found public key: $publicKeyPath"
            break
        }
    }
}

if (-not ($publicKeyPath -and (Test-Path $publicKeyPath))) {
    Write-Error "No suitable public key found in ~/.ssh/ or specified with -identity. Please generate one using 'ssh-keygen'."
    exit 1
}

# Trim whitespace from key content as this can affect matching
$publicKeyString = (Get-Content -Path $publicKeyPath -Raw).Trim()

try {
    # Step 1: Check if the key already exists to prevent duplicates.
    # grep -F treats the key as a fixed string. -q runs quietly.
    $checkCommand = "grep -F -q -- '${publicKeyString}' ~/.ssh/authorized_keys"
    Write-Verbose "Checking if key exists on $user_at_hostname"
    Write-Verbose "Check command: $checkCommand"
    
    ssh $user_at_hostname $checkCommand 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Key already exists on $user_at_hostname. No changes made."
        exit 0
    } elseif ($LASTEXITCODE -ne 1) {
        # grep returns 0 if found, 1 if not found. Any other code is an error.
        throw "Check command failed with exit code $LASTEXITCODE. This might be a permission issue on the remote directory."
    }

    # Step 2: If key doesn't exist (grep returned 1), proceed to add it.
    Write-Verbose "Key not found. Proceeding to add it."
    $remoteAddCommand = "umask 077; mkdir -p .ssh; echo '${publicKeyString}' >> .ssh/authorized_keys; chmod 600 .ssh/authorized_keys"
    Write-Verbose "Add command: $remoteAddCommand"

    ssh $user_at_hostname $remoteAddCommand | Out-Host

    if ($LASTEXITCODE -ne 0) {
        throw "The ssh command to add the key failed with exit code $LASTEXITCODE."
    }

    Write-Host "✅ Public key copied successfully to $user_at_hostname"
}
catch {
    # --- Start Diagnostic Phase ---
    Write-Warning "Operation failed. Running diagnostics..."

    $remoteUser = if ($user_at_hostname -like '*@*') { ($user_at_hostname -split '@')[0] } else { $env:USERNAME }

    try {
        # Check 1: Ownership of authorized_keys file
        $ownerCheckCommand = 'stat -c "%U" ~/.ssh/authorized_keys 2>/dev/null'
        Write-Verbose "Diagnostic command on ${user_at_hostname}: $ownerCheckCommand"
        $owner = ssh $user_at_hostname $ownerCheckCommand
        
        if ($LASTEXITCODE -eq 0 -and $owner -ne $remoteUser) {
            throw "The file `~/.ssh/authorized_keys` on the server is owned by '$owner', not '$remoteUser'.`nTo fix, run on the server: sudo chown ${remoteUser}:${remoteUser} ~/.ssh/authorized_keys"
        }

        # Check 2: Ownership of .ssh directory
        $dirOwnerCheckCommand = 'stat -c "%U" ~/.ssh 2>/dev/null'
        Write-Verbose "Diagnostic command on ${user_at_hostname}: $dirOwnerCheckCommand"
        $dirOwner = ssh $user_at_hostname $dirOwnerCheckCommand

        if ($LASTEXITCODE -eq 0 -and $dirOwner -ne $remoteUser) {
            throw "The directory `~/.ssh` on the server is owned by '$dirOwner', not '$remoteUser'.`nTo fix, run on the server: sudo chown -R ${remoteUser}:${remoteUser} ~/.ssh"
        }

        # Fallback to generic error
        throw "Could not automatically diagnose the permission issue. Please ensure `~/.ssh` and `~/.ssh/authorized_keys` are owned by '$remoteUser' and have the correct write permissions."
    }
    catch {
        Write-Error $_.Exception.Message
    }
}
