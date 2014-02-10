:: from http://serverfault.com/questions/224810/is-there-an-equivalent-to-ssh-copy-id-for-windows
::usage: ssh-copy-id test@example.com password [id_ras.pub]

::@echo off
IF "%~3"=="" GOTO setdefault
set /p id=<%3
GOTO checkparams
:setdefault
set /p id=<id_rsa.pub
:checkparams
IF "%~1"=="" GOTO promptp
IF "%~2"=="" GOTO promptp2

:exec
:: To accept the signature the first time
echo y | plink.exe %1 -pw %2 "exit"
:: now to actually copy the key
echo %id% | plink.exe %1 -pw %2 "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys"
GOTO end

:promptp
set /p user= "Enter username@remotehost.com: "
:promptp2
set /p pw= "Enter password: "
echo y | plink.exe %user% -pw %pw% "exit"
echo %id% | plink.exe %user% -pw %pw% "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys"
:end
pause
