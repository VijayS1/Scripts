# ssh-copy-id for Windows

A collection of PowerShell scripts to simplify managing SSH key-based authentication on Windows.

## Scripts

### `ssh-check-id.ps1` (Recommended Workflow)

This script provides an interactive way to audit and fix SSH key access across multiple servers.

**Key Features:**
- **Detailed Reporting:** Checks servers and provides a detailed table of results, including specific error statuses like `Authentication Failed` or `Host Unreachable`.
- **Intelligent Config Parsing:** When using the default mode, it automatically resolves the full `user@hostname` connection string from your `~/.ssh/config` file and displays it in the report.
- **Interactive Prompts:** After the report, it interactively prompts you to choose which of the failed servers you want to fix.
- **Real-time Feedback:** Provides live output as it begins checking each server, so it doesn't feel like it's hanging.

**Usage:**

By default, the script audits all non-wildcard hosts from your `~/.ssh/config` file.

```powershell
# Check all hosts in ~/.ssh/config and display a detailed report
.\ssh-check-id.ps1

# Run in verbose mode to see the commands being executed
.\ssh-check-id.ps1 -Verbose

# Check servers from a file
.\ssh-check-id.ps1 -ServerFile .\servers.txt

# Check a specific list of servers
.\ssh-check-id.ps1 -ServerList "server1.com", "user@server2.com"
```

---

### `ssh-copy-id.ps1` (Direct Copy)

This script is a faithful Windows counterpart to the standard Linux `ssh-copy-id` command.

**Key Features:**
- **Prevents Duplicates:** It safely checks if a key already exists on the remote server before adding it.
- **Single Password Prompt:** It uses a single, intelligent SSH connection to perform its checks and add the key, ensuring you are only prompted for a password once (if needed).
- **Advanced Diagnostics:** If the script fails, it attempts to diagnose common server-side permission errors (e.g., `authorized_keys` file owned by `root`) and gives you the exact command to fix the issue.

**Usage:**

```powershell
# Safely copy the best available public key
.\ssh-copy-id.ps1 -user_at_hostname user@example.com

# Copy a specific key and see verbose output for debugging
.\ssh-copy-id.ps1 -user_at_hostname user@example.com -identity .\my_key.pub -Verbose
```

---

### Legacy & Specialized Scripts

These scripts are maintained for compatibility or specific use cases.

*   **`ssh-copy-id.cmd`**: A Command Prompt version that copies a key to a single host.
*   **`ssh-copy-id.vbs`**: A VBScript version for legacy environments.
*   **`ssh-copy-id.bat`**: A specialized script designed to be called *by WinSCP only*. It is not a standalone script.
