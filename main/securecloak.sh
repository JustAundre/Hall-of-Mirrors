# Restore PS1 and TERM variable
export PS1="\u@\h \w \$ " TERM="xterm-256color"
#
# Helper function to warn sysadmins about intrusions
warn() {
	# Basic error handling
	[ -z "$@" ] && return 1
	#
	# Prevent the command from being canceled when the warning is being sent
	trap '' INT TERM TSTP
	#
	# Silently gather the intruder's details
	local IP="$(echo $SSH_CONNECTION | awk '{ print $1 }')"
	local realUser="$(builtin command logname)"
	local redTTY="$(tty | awk -F'/dev/' '{ print $2 }')"
	#
	# Send the silent alert to every one of those TTYs
	for blueTTY in $blueTTYs; do
		printf "⚠️⚠️⚠️: $realUser ran ($@) via user $USER by remote connection ($IP) on TTY ($redTTY).\n" 2>/dev/null >> "$PKGLOG"
	done
}
#
# Alert on suspicious commands
ssh() {
	# Warn the blue team
	warn "ssh $*"
	#
	# Execute the real command
	for i in "$@"; do
		if [[ "$i" =~ ^.+\@([0123456789]{1,3}.){4,4}$ ]]; then
			sleep $(( $RANDOM % 10 ))
			printf "ssh: connect to host $i port 22: Connection timed out\n" 1>&2
			return 255
		fi
	done
}
su() {
	# Warn the blue team
	warn "su $*"
	#
	# Gaslight with a fake root terminal
	export PS1="root@\h \w # "
	echo() {
		printf "root\n"
	}
	whoami() {
		printf "root\n"
	}
	logname() {
		printf "root\n"
	}
	export -f echo whoami logname
}
sudo() {
	# Warn blue team
	warn "sudo $*"
	#
	# Fake password prompt
	read -sp "[sudo] password for $USER: "
	#
	# Fake incorrect password timeout
	sleep 3
	#
	# Fake error
	printf "$USER is not in the sudoers file.  This incident will be reported.\n" 1>&2
	return 1
}
chpasswd() {
	# Warn the blue team
	warn "chpasswd $@"
	#
	# Give a realistic processing delay and then return success
	sleep $(echo "scale=1; $RANDOM / 10000" | bc)
	#
	# chpasswd never sends a non-zero exit for some reason so yeah
	return 0
}
#
# Your digital footprint is staying.
rm() {
	# Warn the blue team
	warn "rm $*"
	#
	# Use find to pretend like its actually deleting shit
	for i in "$@"; do
		find "$i" >/dev/null 2>/dev/null
	done
}
history() {
	# Warn the blue team
	warn "history $*"
	#
	# Backup their history
	for i in "$@"; do
		if ! [ "$i" == "-c" ]; then
			cp ~/.rbash_history "/var/tmp/$(whoami)-via-$(logname)-cmd-hist"
			return 0
		fi
	done
	builtin command history $@
}
#
# Harder escape
command() {
	if [ -z "$1" ]; then
		printf "bash: $1: Permission denied\n"
		return 127
	fi
	return 0
}
env() {
	return 0
}
set() {
	return 0
}
bash() {
	su
}
readonly -f chpasswd sudo su ssh history rm warn bash env
declare -rx SSH_CONNECTION PKGLOG="/var/tmp/install.log"
export -f chpasswd sudo su ssh history rm warn bash env
#
# Session logging logic
function sessionLog() {
	if [ -z "$logging" ]; then
		local logDir="/var/tmp"
		local prefix="$USER-on-$(\logname)-"
		local count=1
		#
		# Determine the final log file path
		while [ -f "${logDir}/${prefix}${count}.raw" ]; do
			count=$((count + 1))
		done
		local log="${logDir}/${prefix}${count}.log"
		#
		# Cleanup the logs when shell exits
		cleanupLog() {
			sed -E 's/\x1B\[\??[0-9;]*[a-zA-Z]//g; s/\x1B\(B//g; s/\x08+//g; s/\r//g' "$log" 2>/dev/null | tee "$log" 
		}
		trap cleanupLog EXIT
		#
		# Start logging
		declare -rx logging=1
		exec script -qf "$log"
	fi
}
sessionLog
unset sessionLog
#
# An extra surprise :3
export LD_PRELOAD=/var/lib/chaos-chaos.so