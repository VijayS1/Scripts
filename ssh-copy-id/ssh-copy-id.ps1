<#
 .NAME
    ssh-copy-id.ps1
 .SYNOPSIS
    Safely copies a public SSH key to a remote host, checking for existing keys first.
 .DESCRIPTION
    This script replicates the functionality of the Linux `ssh-copy-id` utility on Windows.
    It uses a single SSH connection to remotely check if the key already exists and only adds it if it's missing. This prevents duplicate keys and avoids multiple password prompts.
    If the operation fails, it attempts to diagnose common server-side permission issues.
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
    # This entire script block is executed on the remote server in a single session.
    # This prevents multiple password prompts.
    $remoteScript = @"
# This entire script block is executed on the remote server in a single session.
# This prevents multiple password prompts.
KEY='${publicKeyString}'
AUTH_FILE="~/.ssh/authorized_keys"
SSH_DIR=`$(dirname "`$AUTH_FILE`")`

# Ensure the .ssh directory exists and has the correct permissions.
if [ ! -d "`$SSH_DIR`" ]; then
  mkdir -p "`$SSH_DIR`"
  chmod 700 "`$SSH_DIR`"
fi

# Ensure the authorized_keys file exists and has the correct permissions.
if [ ! -f "`$AUTH_FILE`" ]; then
  touch "`$AUTH_FILE`"
  chmod 600 "`$AUTH_FILE`"
fi

# Check if the key already exists.
if grep -F -q -- "`$KEY`" "`$AUTH_FILE`"; then
  echo "✅ Key already exists on server. No changes made."
  exit 0
else
  # Key does not exist, so append it.
  echo "`$KEY`" >> "`$AUTH_FILE`"
  if [ `$?` -eq 0 ]; then
    echo "✅ Key successfully added to server."
    exit 0
  else
    echo "❌ Failed to add key to file." >&2
    exit 1
  fi
fi
"@

    Write-Verbose "Executing remote script on $user_at_hostname"
    # The remote script is piped to Out-Host to ensure its output is displayed smoothly.
    ssh $user_at_hostname $remoteScript | Out-Host

    if ($LASTEXITCODE -ne 0) {
        throw "The remote script failed with exit code $LASTEXITCODE."
    }
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