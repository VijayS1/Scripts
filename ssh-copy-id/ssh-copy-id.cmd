@echo off
:: Replicates ssh-copy-id functionality on Windows using native ssh.exe
:: Usage: ssh-copy-id user@example.com [identity_file]

setlocal

set USER_HOST=%1
set IDENTITY_FILE=%2

if "%USER_HOST%"=="" (
    echo "Usage: %~n0 user@host [identity_file]"
    goto :eof
)

if "%IDENTITY_FILE%"=="" (
    if exist "%USERPROFILE%\.ssh\id_ed25519.pub" (
        set "IDENTITY_FILE=%USERPROFILE%\.ssh\id_ed25519.pub"
    ) else if exist "%USERPROFILE%\.ssh\id_ecdsa.pub" (
        set "IDENTITY_FILE=%USERPROFILE%\.ssh\id_ecdsa.pub"
    ) else (
        set "IDENTITY_FILE=%USERPROFILE%\.ssh\id_rsa.pub"
    )
)

if not exist "%IDENTITY_FILE%" (
    echo "Identity file not found: %IDENTITY_FILE%"
    echo Please generate a key pair using 'ssh-keygen' or specify the path to your public key.
    exit /b 1
)

echo "Using identity file: %IDENTITY_FILE%"
echo "Attempting to copy public key to %USER_HOST%..."
echo "You will be prompted for the password."

type "%IDENTITY_FILE%" | ssh %USER_HOST% "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

if %errorlevel% neq 0 (
    echo "Failed to copy key."
    exit /b %errorlevel%
)

echo "Key copied successfully."
endlocal
