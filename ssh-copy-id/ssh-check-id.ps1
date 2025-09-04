<#
 .SYNOPSIS
    Checks SSH key-based authentication on a list of servers, then prompts to copy keys to any that failed. 
 .DESCRIPTION
    This script first checks a list of servers for passwordless SSH login. The server list is sourced from the ~/.ssh/config file by default, or can be provided via the -ServerList or -ServerFile parameters.

    After checking all servers, it presents a list of any servers that failed the authentication check. It then prompts the user to select which of these servers they would like to copy the public key to.

    For the selected servers, it calls the `ssh-copy-id.ps1` script to perform the key-copying operation, which will be interactive and may prompt for a password.
 .PARAMETER ServerList
    An array of server hostnames or user@hostname strings to check.
 .PARAMETER ServerFile
    The path to a text file containing a list of servers (one per line).
 .PARAMETER IdentityFile
    The path to a specific public key file to use for checking and copying. If not provided, the script auto-detects the key.
 .EXAMPLE
    # Default behavior: Check all hosts from ~/.ssh/config and then prompt for which ones to fix.
    .\ssh-check-id.ps1

 .EXAMPLE
    # Check servers from a file
    .\ssh-check-id.ps1 -ServerFile C:\path\to\servers.txt

 .EXAMPLE
    # Check specific servers from a list
    .\ssh-check-id.ps1 -ServerList "user@server1.com", "server2.com"
#>
Param(
    [Parameter(ValueFromPipeline=$true)]
    [String[]]$ServerList,

    [Parameter()]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]$ServerFile,

    [Parameter(HelpMessage="Specify the public key file to check. If not provided, the script will search for common key types.")]
    [ValidateScript({Test-Path $_})]
    [Alias("i")]
    [String]$IdentityFile
)

# --- Server List Preparation ---
$servers = @()

if ($ServerList) {
    if ($ServerFile) {
        Write-Error "Please use either -ServerList or -ServerFile, not both."
        exit 1
    }
    $servers = $ServerList
} elseif ($ServerFile) {
    try {
        $servers = Get-Content -Path $ServerFile
    }
    catch {
        Write-Error "Failed to read server file '$ServerFile': $_"
        exit 1
    }
} else {
    # Default to reading from ~/.ssh/config
    $sshConfigFile = Join-Path $env:USERPROFILE ".ssh\config"
    if (Test-Path $sshConfigFile) {
        Write-Host "No server list provided. Defaulting to hosts from $sshConfigFile"
        $content = Get-Content $sshConfigFile
        $parsedHosts = $content | ForEach-Object {
            if ($_ -match "^\s*Host\s+([^\s*?]+)\s*$") {
                $matches[1].Split(' ')
            }
        }
        $servers = $parsedHosts | Select-Object -Unique
    } else {
        Write-Error "No server list provided and SSH config file not found at $sshConfigFile. Please provide a server list or create a config file."
        exit 1
    }
}

if ($servers.Count -eq 0) {
    Write-Warning "No servers to check."
    exit 0
}

# --- Key Selection Logic ---
$publicKeyPath = $null
if ($IdentityFile) {
    $publicKeyPath = $IdentityFile
} else {
    $sshDir = "$($env:USERPROFILE)\.ssh"
    $keyFiles = @("id_ed25519.pub", "id_ecdsa.pub", "id_rsa.pub")

    foreach ($keyFile in $keyFiles) {
        $potentialKey = Join-Path $sshDir $keyFile
        if (Test-Path $potentialKey) {
            $publicKeyPath = $potentialKey
            break
        }
    }
}

if (-not ($publicKeyPath -and (Test-Path $publicKeyPath))) {
    Write-Error "No suitable public key found to check or copy. Please generate one using 'ssh-keygen' or specify a valid key with -IdentityFile."
    exit 1
}

Write-Host "Using public key: $publicKeyPath"

# --- Main Checking Loop ---
$failedServers = [System.Collections.Generic.List[string]]::new()
Write-Host "`n--- Starting Server Checks ---"
foreach ($server in $servers) {
    if (-not ([string]::IsNullOrWhiteSpace($server))) {
        Write-Host "Checking: $server..." -NoNewline
        try {
            ssh -o BatchMode=yes -o ConnectTimeout=5 $server "exit" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✅ OK" -ForegroundColor Green
            } else {
                throw "Auth failed or host unreachable."
            }
        }
        catch {
            Write-Host " ❌ Failed" -ForegroundColor Red
            $failedServers.Add($server)
        }
    }
}

# --- Post-Check Prompt and Copy Action ---
if ($failedServers.Count -eq 0) {
    Write-Host "`n✨ All servers passed authentication check." -ForegroundColor Green
    exit 0
}

Write-Warning "`nThe following servers failed the authentication check:"
for ($i = 0; $i -lt $failedServers.Count; $i++) {
    Write-Host (" {0,3}) {1}" -f ($i + 1), $failedServers[$i])
}

$prompt = "`nEnter the numbers of the servers to copy the key to (e.g., '1,3'), 'all', or 'none' to exit:"
$choice = Read-Host -Prompt $prompt

$serversToCopy = @()
if ($choice.ToLower() -eq 'all') {
    $serversToCopy = $failedServers
} elseif ($choice.ToLower() -ne 'none') {
    $indices = $choice -split ',' | ForEach-Object { $_.Trim() }
    foreach ($indexStr in $indices) {
        if ($indexStr -match '\d+' -and [int]$indexStr -ge 1 -and [int]$indexStr -le $failedServers.Count) {
            $serversToCopy += $failedServers[[int]$indexStr - 1]
        } else {
            Write-Warning "Invalid selection: $indexStr"
        }
    }
}

if ($serversToCopy.Count -gt 0) {
    Write-Host "`n--- Copying Keys ---"
    $copyScriptPath = Join-Path $PSScriptRoot "ssh-copy-id.ps1"
    if (-not (Test-Path $copyScriptPath)) {
        Write-Error "Could not find ssh-copy-id.ps1 in the same directory. Aborting."
        exit 1
    }

    foreach ($server in $serversToCopy) {
        Write-Host "`nRunning ssh-copy-id for $server..."
        try {
            & $copyScriptPath -user_at_hostname $server -identity $publicKeyPath
        }
        catch {
            Write-Error -Message "An error occurred while running ssh-copy-id.ps1 for $server." -ErrorRecord $_ 
        }
    }
} else {
    Write-Host "`nNo servers selected for key copying. Exiting."
}
