#!/bin/bash
# Curly brackets to stop output of staging commands
{
	# Set secure/safe shell configurations
	set +o xtrace verbose monitor nolog ignoreeof
	set -o functrace errtrace pipefail nounset noclobber
	shopt -s histappend histverify cmdhist dotglob globstar interactive_comments
	shopt -u cdable_vars cdspell dirspell extglob nocaseglob nocasematch expand_aliases progcomp
	umask 0077
	#
	# Lock down variables
	read -r PROMPT_COMMAND <<-'EOF'
		history -a
		history -w
		sleep .15
	EOF
	declare -rx HISTIGNORE=
	declare -rx HISTCONTROL='ignoreboth'
	declare -rx LD_PRELOAD=
	declare -rx HISTSIZE=-1
	declare -rx HISTFILESIZE=-1
	declare -rx PATH='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin'
	TTY=$(tty)
	declare -rx TTY="${TTY##*/}"
	declare -rx SSH_TTY="$TTY"
	UID=$(</proc/self/loginuid)
	if [[ "$UID" == 4294967295 ]]; then
		UID="$(id -u)"
	fi
	declare -rx UID
	declare -rx USER=$(
		getent passwd "$UID" |
			cut -d: -f1
	)
	declare -rx LOGNAME="$USER"
	declare -rx HOME="$(getent passwd $USER | cut -f6)"
	declare -rx HISTFILE="$HOME/.bash_history"
	HOSTNAME=$(hostname)
	declare -rx HOSTNAME="${HOSTNAME%%.*}"
	for var in SSH_CONNECTION SSH_CLIENT; do
		if [[ -z "$var" ]]; then
			declare -rx "$var=Local"
		else
			declare -rx "$var"
		fi
	done
	#
	# Remove usage of commands which allow bypasses or unauthorized forensics
	builtin enable -n set shopt umask kill builtin command getopts unalias ulimit disown enable times alias echo printf
} &>/dev/null