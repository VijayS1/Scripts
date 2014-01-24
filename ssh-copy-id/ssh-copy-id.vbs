'
'	ssh-copy-id.vbs
'
' Purpose: Copy public key to remote hosts
'
' .EXAMPLES
'    .\Scriptname /i:idtest.pub user@example.com /p:password
'    .\ScriptName user@example.com /p:password
' 
' 
'	Written by VijayS,
' 
'

Option Explicit

' Run the Function :)
Call CheckParameters

Sub CheckParameters()

	Dim fso
	Set fso = createobject("scripting.filesystemobject")

	Dim user_host
	Dim identityfile
	Dim password

	Dim iNumberOfArguments
	Dim colNamedArguments

	iNumberOfArguments = WScript.Arguments.Count
	Set colNamedArguments = WScript.Arguments.Named
	If iNumberOfArguments = 0 Then
		WScript.Echo "Error: No connection string provided!" & vbcrlf _
			& "Usage: Scriptname user@hostname.com [/i:identityfile] [/p:password]" & vbcrlf _
			& " Identity file defaults to ./id_rsa.pub"
		WScript.Quit
	ElseIf iNumberOfArguments >= 1 Then
		' if 1 argument is provided ASSUME it's destination folder
		user_host = WScript.Arguments.Unnamed.Item(0)
	End If

	If Not colNamedArguments.Exists("i") Then
		identityfile = ".\id_rsa.pub"
	else
		identityfile = colNamedArguments.Item("i")
	End If 

	If Not colNamedArguments.Exists("p") Then
		password = ""
	else
		password = colNamedArguments.Item("p")
	End If 

	'identityfile = fso.GetAbsolutePathName(".")
	If Not fso.FileExists(identityfile) Then
		Wscript.Echo "Error: identity file not found: " & identityfile
		Wscript.Quit
	End If
	Set fso = nothing

	Dim cmdline
	cmdline = GenCommand(user_host, password, identityfile)
	'Wscript.Echo cmdline
	Wscript.Echo getCommandOutput("cmd /c " & cmdline)	
End Sub

Function GenCommand(user_host, password, identityfile)
	Dim pw
	Dim cmd
	If password <> vbNullString Then
		pw = " -pw " & password
	End If
	cmd = "type " & identityfile & " | .\plink.exe " & user_host & pw & _
	" ""umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys"""
	GenCommand = cmd
End Function

'
' Capture the results of a command line execution and
' return them to the caller.
'
Function getCommandOutput(theCommand)
    Dim objShell, objCmdExec
    Set objShell = CreateObject("WScript.Shell")
    Set objCmdExec = objshell.exec(thecommand)
    getCommandOutput = objCmdExec.StdOut.ReadAll
    Set objshell = nothing
    Set objCmdExec = nothing
End Function