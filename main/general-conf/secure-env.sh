# Hide terminal feedback
stty -echo
#
# Set secure shell configurations
set +x
set -o functrace
set -o errtrace
set -o ignoreeof
set -o pipefail
set +o nolog
shopt -s histappend
#
# Remove ability to change shell configurations
umask 0037
enable -n set shopt umask kill builtin command getopts unalias ulimit disown enable times echo printf
#
# Lock down variables
declare -rx\
	PROMPT_COMMAND='
		history -a
		history -w
		sleep 0.2
	'\
	LOG\
	SSH_CONNECTION\
	SSH_CLIENT\
	TTY="${SSH_TTY##*/}"\
	SSH_TTY="${SSH_TTY##*/}"\
	SSH_ORIGINAL_COMMAND\
	HOSTNAME\
	USER\
	LUID\
	LOGNAME\
	HOME\
	HISTIGNORE=\
	HISTCONTROL=\
	HISTSIZE=10000\
	HISTFILESIZE=10000\
	HISTFILE="$HOME/.bash_history"\
	TMOUT=90
#
# Restore terminal feedback
stty echo