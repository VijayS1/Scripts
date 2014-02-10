# WINSCP script

# example commandline arguments from mremoteNG
# "WinSCP.com"  /script="ssh-copy-id.bat" /log="ssh-copy-id.log" /parameter "%username%:%password%@%hostname%" "id_rsa.pub"
# "WinSCP.com"  /script="ssh-copy-id.bat" /log="ssh-copy-id.log" /parameter "user@example.com" "id_rsa.pub"

# Automatically answer all prompts negatively not to stall
# the script on errors
option batch on
# Disable overwrite confirmations that conflict with the previous
option confirm off
open -hostkey=* sftp://%1%
option transfer binary

#change permissions to be restrictive
call umask 077
#test and create .ssh director if it doesn't exist
call test -d .ssh || mkdir .ssh
#copy public key, append to file and remove it
put -append %2% .ssh/authorized_keys
put -append %3% .ssh/authorized_keys
put -append %4% .ssh/authorized_keys

close
exit