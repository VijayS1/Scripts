'
'	ssh-copy-id.vbs
'
' Purpose: Copy public key to remote hosts using native ssh.exe
'
' .EXAMPLES
'    cscript ssh-copy-id.vbs user@example.com [/i:identityfile.pub]
'
'	Written by VijayS,
'
Option Explicit

Call Main

Sub Main()
    Dim fso, shell
    Set fso = CreateObject("scripting.filesystemobject")
    Set shell = CreateObject("WScript.Shell")

    Dim user_host, identityFile, homePath

    If WScript.Arguments.Unnamed.Count <> 1 Then
        WScript.Echo "Usage: cscript " & WScript.ScriptName & " user@hostname.com [/i:identityfile.pub]"
        WScript.Quit(1)
    End If

    user_host = WScript.Arguments.Unnamed.Item(0)

    If WScript.Arguments.Named.Exists("i") Then
        identityFile = WScript.Arguments.Named.Item("i")
    Else
        homePath = shell.ExpandEnvironmentStrings("%USERPROFILE%")
        Dim keyFiles(2), keyFile, potentialKey, foundKey
        keyFiles(0) = "id_ed25519.pub"
        keyFiles(1) = "id_ecdsa.pub"
        keyFiles(2) = "id_rsa.pub"
        foundKey = False

        For Each keyFile In keyFiles
            potentialKey = fso.BuildPath(fso.BuildPath(homePath, ".ssh"), keyFile)
            If fso.FileExists(potentialKey) Then
                identityFile = potentialKey
                foundKey = True
                Exit For
            End If
        Next

    End If

    If Not fso.FileExists(identityFile) Then
        WScript.Echo "Error: Identity file not found." & vbCrLf & "Looked for: " & identityFile & vbCrLf & "Please generate a key or specify the path using /i:your_key.pub"
        WScript.Quit(1)
    End If

    WScript.Echo "Using identity file: " & identityFile
    WScript.Echo "Attempting to copy public key to " & user_host
    WScript.Echo "You may be prompted for the password."

    Dim command, exitCode
    command = "cmd /c type """ & identityFile & """ | ssh " & user_host & " ""mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"""

    exitCode = shell.Run(command, 1, True) ' 1 = show window, True = wait for completion

    If exitCode = 0 Then
        WScript.Echo "Key copied successfully."
    Else
        WScript.Echo "Failed to copy key. Exit code: " & exitCode
    End If

    Set fso = Nothing
    Set shell = Nothing
End Sub