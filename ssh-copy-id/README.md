ssh-copy-id
=======

Various scripts duplicating ssh-copy-id behavior in windows. All scripts depend on **plink.exe** which you can download from [here](http://the.earth.li/~sgtatham/putty/latest/x86/plink.exe)

Attempted methods so far:

- DOS(.cmd) - Success
 - `usage: .\Scriptname test@example.com password [identity file] `
- VBS (.vbs) - Success
 - `usage: .\Scriptname /i:idtest.pub user@example.com /p:password `
- Powershell(.ps1) - Success
 - `usage: .\Scriptname -i idtest.pub user@example.com password` 
- mremoteNG (ext app) - Success
 - Select Host, right click, external tools, select Scriptname 
- WinSCP script (.bat) - Success
 - `# "WinSCP.com"  /script=".\Scriptname" /parameter "user[:password]@example.com" "id_rsa.pub" [/log=".\copyssh.log]"` 

Still to try:

- Batch processing using one of the scripts above. (preferrably powershell). Load hosts.txt & keys.txt and loop over them.
- GUI application (.net? ahk?)
- Check Keys mode. If input is substring of keys file. 


---
Desired Features:

1. ability to enter mulltiple connection strings and passwords
1.   ability to specify multiple public keys
1.   checking feature: which shows which servers you have access to with your currently selected private key? or public key? (if public key then need to provide password for remote sites again, or use another known private key?). Remember this? maintain a state? and can periodically refresh?
1. have a default mode: prompt for key, remotestring and password
1. check .authorized_keys to see if the key already exists?