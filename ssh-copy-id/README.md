# ssh-copy-id for Windows

A collection of PowerShell scripts to simplify managing SSH key-based authentication on Windows.

## Scripts

### `ssh-check-id.ps1` (Recommended Workflow)

This script provides a powerful, interactive way to audit and fix SSH key access across multiple servers.

**How it works:**
1.  It first checks a list of servers to see if key-based authentication is working.
2.  After checking all servers, it provides a summary report of which ones passed and which failed.
3.  It then interactively prompts you to choose which of the failed servers you want to copy a key to.

**Usage:**

By default, the script will automatically get the list of servers from your `~/.ssh/config` file.

```powershell

# Check all hosts in ~/.ssh/config and then interactively fix failures
.\/ssh-copy-id.ps1
```

You can also provide a list of servers from a file or directly on the command line.

```powershell

# Check servers listed in a file
.
/ssh-check-id.ps1 -ServerFile C:\path\to\servers.txt

# Check a specific list of servers
.
/ssh-check-id.ps1 -ServerList "server1.com", "user@server2.com"

# Use a specific identity file for checking
.
/ssh-check-id.ps1 -IdentityFile C:\Users\user\.ssh\work_key.pub
```

---


### `ssh-copy-id.ps1` (Direct Copy)

This script copies a public SSH key to a single remote host, replicating the basic functionality of the Linux `ssh-copy-id` command. It will prompt for a password if required.

If no identity file is specified, it automatically searches for and uses the first key found in the following order: `id_ed25519.pub`, `id_ecdsa.pub`, then `id_rsa.pub`.

```powershell

# Automatically find and copy the best available public key
.
/ssh-copy-id.ps1 -user_at_hostname user@example.com

# Copy a specific public key
.
/ssh-copy-id.ps1 -user_at_hostname user@example.com -identity C:\Users\YourUser\.ssh\my_key.pub
```

---


### Legacy & Specialized Scripts

These scripts are maintained for compatibility or specific use cases.

*   **`ssh-copy-id.cmd`**: A Command Prompt version that copies a key to a single host.
*   **`ssh-copy-id.vbs`**: A VBScript version for legacy environments.
*   **`ssh-copy-id.bat`**: A specialized script designed to be called *by WinSCP only*. It is not a standalone script.

```