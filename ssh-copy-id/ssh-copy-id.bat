# WINSCP script

# example commandline arguments from mremoteNG
# ".\ExternalTools\WinSCP.com"  /script=".\ExternalTools\ssh-copy-id.bat" /parameter "%username%:%password%@%hostname%" ".\ExternalTools\id_rsa.pub" /log=".\ExternalTools\copyssh.log"

#Thu January 23, 2014 08:52:23 PM
# not working so far, as the %2% is not getting properly converted somehow


# Automatically answer all prompts negatively not to stall
# the script on errors
option batch on
# Disable overwrite confirmations that conflict with the previous
option confirm off
# Connect using a password
open %1%
# Force binary mode transfer
option transfer binary

#change permissions to be restrictive
call umask 077
#test and create .ssh director if it doesn't exist
call test -d .ssh || mkdir .ssh
#copy public key, append to file and remove it
put -append %2% .ssh/authorized_keys
#call cat %2% >> .ssh/authorized_keys
#rm %2%

# Change the local directory
# Disconnect
close
# Exit WinSCP
exit