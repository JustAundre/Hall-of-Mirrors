#!/bin/bash
# Curly brackets to stop output of staging commands
{
	# Set secure/safe shell configurations
	set +o xtrace verbose monitor nolog ignoreeof
	set -o functrace errtrace pipefail nounset noclobber
	shopt -s histappend histverify cmdhist dotglob globstar
	shopt -u cdable_vars cdspell dirspell interactive_comments extglob nocaseglob nocasematch expand_aliases
	umask 0077
	#
	# Disable builtin echo and printf so they're forced to make syscalls to the actual binaries
	enable -n echo printf
	#
	# Remove usage of commands which allow bypasses or unauthorized forensics
	enable -n set shopt umask kill builtin command getopts unalias ulimit disown enable times alias
	#
	# Lock down variables
	TTY="$(tty)"
	read -r PROMPT_COMMAND <<-'EOF'
		history -a
		history -w
		USER="$(getent passwd $UID | cut -d: -f1)"
		sleep 0.15
	EOF
	TMOUT=90
	declare -rx\
		SSH_CONNECTION\
		SSH_CLIENT\
		SSH_TTY="${TTY##*/}"\
		TTY="${TTY##*/}"\
		SSH_ORIGINAL_COMMAND\
		HOSTNAME="${HOSTNAME%%.*}"\
		LOGNAME\
		HOME\
		HISTIGNORE=\
		HISTCONTROL=\
		LD_PRELOAD=\
		HISTSIZE=10000\
		HISTFILESIZE=10000\
		HISTFILE="$HOME/.bash_history"\
		UID="$(/usr/bin/cat /proc/self/loginuid)"\
		PROMPT_COMMAND
} >/dev/null