#
# Functions
#
# Helper function to warn sysadmins about intrusions
warn() {
	# Basic error handling
	[ -z "$@" ] && return 1
	#
	# Prevent the command from being canceled when the warning is being sent
	trap '' INT TERM TSTP
	#
	# Send the silent alert
	echo "⚠️⚠️⚠️: $USER ran a risky from $userIP on $TTY. Command was: $*" | tee -a "$PKGLOG" &>/dev/null | systemd-cat -t "sshd-internal" -p 3
	#
	# Remove the trap
	trap - INT TERM TSTP
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
			echo "ssh: connect to host $i port 22: Connection timed out" 1>&2
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
	whoami() { echo "root"; }
	logname() { echo "root"; }
	declare -rfx whoami logname
}
sudo() {
	# Warn blue team
	warn "sudo $*"
	#
	# Fake password prompt
	read -sp "[sudo] password for $USER: "
	#
	# Fake incorrect password timeout
	sleep 2.5
	#
	# Fake error
	echo "$USER is not in the sudoers file.  This incident will be reported." 1>&2
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
# Prevent removal of traces
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
# Slightly impede attempts to escape securecloak.
command() {
	if [ -z "$1" ]; then
		local cmd=$(printf "$1" | awk '{ print $1 }')
		echo "bash: $cmd: Permission denied"
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
	sleep .25
	su
}
declare -rfx chpasswd sudo su ssh history rm warn bash env





#
# Session Logging
#
# Log the entire session to a file.
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