# Hide terminal feedback
stty -echo
#
# Set secure shell configurations
set +x nolog
set -o functrace errtrace ignoreeof pipefail
shopt -s histappend
#
# Remove ability to change shell configurations
umask 0037
enable -n set shopt umask kill builtin command getopts unalias ulimit disown enable times echo printf
#
# Lock down variables
TTY=$(tty)
declare -rx\
	PROMPT_COMMAND='
		history -a
		history -w
		sleep 0.15
	'\
	LOG\
	SSH_CONNECTION\
	SSH_CLIENT\
	TTY="${TTY##*/}"\
	SSH_TTY="${TTY##*/}"\
	SSH_ORIGINAL_COMMAND\
	HOSTNAME="${HOSTNAME%%.*}"\
	USER\
	LUID\
	LOGNAME\
	HOME\
	HISTIGNORE=\
	HISTCONTROL=\
	HISTSIZE=10000\
	HISTFILESIZE=10000\
	HISTFILE="$HOME/.bash_history"
TMOUT=90
#
# Restore terminal feedback
stty echo