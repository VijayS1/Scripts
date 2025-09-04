<#
 .SYNOPSIS
    Checks SSH key-based authentication on a list of servers, provides a detailed report, and offers to copy keys to any that failed.
 .DESCRIPTION
    This script first checks a list of servers for passwordless SSH login. It provides a detailed report in a table format, showing the exact status for each server (e.g., OK, Host Unreachable, Auth Failed).

    After displaying the report, it presents a list of any servers that failed the authentication check and prompts the user to select which of these servers they would like to copy the public key to.
 .PARAMETER ServerList
    An array of server hostnames or user@hostname strings to check.
 .PARAMETER ServerFile
    The path to a text file containing a list of servers (one per line).
 .PARAMETER IdentityFile
    The path to a specific public key file to use for checking and copying. If not provided, the script auto-detects the key.
 .EXAMPLE
    # Default behavior: Check all hosts from ~/.ssh/config and display a detailed report.
    .\ssh-check-id.ps1
#>
[CmdletBinding()]
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
$serverInfoList = [System.Collections.Generic.List[PSCustomObject]]::new()

if ($ServerList) {
    if ($ServerFile) {
        Write-Error "Please use either -ServerList or -ServerFile, not both."
        exit 1
    }
    $ServerList | ForEach-Object { $serverInfoList.Add([PSCustomObject]@{ Alias = $_; ConnectionString = $_ }) }
} elseif ($ServerFile) {
    try {
        Get-Content -Path $ServerFile | ForEach-Object { $serverInfoList.Add([PSCustomObject]@{ Alias = $_; ConnectionString = $_ }) }
    }
    catch {
        Write-Error -Message "Failed to read server file '$ServerFile'." -ErrorRecord $_ 
        exit 1
    }
} else {
    # Default to reading from ~/.ssh/config
    $sshConfigFile = Join-Path $env:USERPROFILE ".ssh\config"
    if (Test-Path $sshConfigFile) {
        Write-Verbose "No server list provided. Defaulting to hosts from $sshConfigFile"
        $content = Get-Content $sshConfigFile
        $hostAliases = $content | ForEach-Object {
            if ($_ -match "^\s*Host\s+([^\s*?]+)\s*$") {
                $matches[1].Split(' ')
            }
        } | Select-Object -Unique

        foreach ($alias in $hostAliases) {
            try {
                Write-Verbose "Resolving connection string for host alias: $alias"
                $config = ssh -G $alias | ForEach-Object { $parts = $_.Split(' ', 2); @{ ($parts[0]) = $parts[1] } }
                $user = $config.user
                $hostname = $config.hostname
                $port = $config.port
                $connectionString = if ($port -ne 22) { "${user}@${hostname} -p ${port}" } else { "${user}@${hostname}" }
                $serverInfoList.Add([PSCustomObject]@{ Alias = $alias; ConnectionString = $connectionString })
            } catch {
                Write-Warning "Could not resolve connection details for host '$alias'. It might be a wildcard or invalid host. Skipping."
            }
        }
    } else {
        Write-Error "No server list provided and SSH config file not found at $sshConfigFile. Please provide a server list or create a config file."
        exit 1
    }
}

if ($serverInfoList.Count -eq 0) {
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
        if (Test-Path $potentialKey) { $publicKeyPath = $potentialKey; break }
    }
}

if (-not ($publicKeyPath -and (Test-Path $publicKeyPath))) {
    Write-Error "No suitable public key found to check or copy. Please generate one using 'ssh-keygen' or specify a valid key with -IdentityFile."
    exit 1
}

Write-Verbose "Using public key: $publicKeyPath"

# --- Main Checking Loop ---
$results = @()
Write-Host "`n--- Starting Server Checks ---"
foreach ($serverInfo in $serverInfoList) {
    if (-not ([string]::IsNullOrWhiteSpace($serverInfo.ConnectionString))) {
        $status = ""
        Write-Host "Checking alias ' $($serverInfo.Alias)' ($($serverInfo.ConnectionString))..."
        try {
            $sshError = ssh -o BatchMode=yes -o ConnectTimeout=5 $serverInfo.ConnectionString "exit" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $status = "✅ OK"
            } else {
                if ($sshError -like "*Permission denied*") { $status = "❌ Authentication Failed" }
                elseif ($sshError -like "*Connection timed out*" -or $sshError -like "*Connection refused*") { $status = "❌ Host Unreachable" }
                else { $status = "❌ Connection Error" }
            }
        } catch {
            $status = "❌ Script Error"
        }
        $results += [PSCustomObject]@{ Alias = $serverInfo.Alias; ConnectionString = $serverInfo.ConnectionString; Status = $status }
    }
}

# --- Display Results Table ---
Write-Host "`n--- Server Status Report ---"
$results | Format-Table -AutoSize

# --- Post-Check Prompt and Copy Action ---
$failedServers = $results | Where-Object { $_.Status -ne "✅ OK" }

if ($failedServers.Count -eq 0) {
    Write-Host "`n✨ All servers passed authentication check." -ForegroundColor Green
    exit 0
}

Write-Warning "`nThe following servers failed the authentication check:"
for ($i = 0; $i -lt $failedServers.Count; $i++) {
    Write-Host (" {0,3}) {1} ({2})" -f ($i + 1), $failedServers[$i].Alias, $failedServers[$i].ConnectionString)
}

$prompt = "`nEnter the numbers of the servers to copy the key to (e.g., '1,3'), 'all', or press Enter to exit:"
$choice = Read-Host -Prompt $prompt

if ([string]::IsNullOrWhiteSpace($choice)) { $choice = 'none' }

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
        Write-Host "`nRunning ssh-copy-id for $($server.ConnectionString)..."
        try {
            $copyParams = @{ user_at_hostname = $server.ConnectionString; identity = $publicKeyPath }
            if ($PSBoundParameters['Verbose']) { $copyParams['Verbose'] = $true }
            & $copyScriptPath @copyParams
        } catch {
            Write-Error -Message "An error occurred while running ssh-copy-id.ps1 for $($server.ConnectionString)." -ErrorRecord $_ 
        }
    }
} else {
    Write-Host "`nNo servers selected for key copying. Exiting."
}