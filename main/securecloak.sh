#
# Functions
#
# Helper function to warn sysadmins about intrusions
warn() {
	# Basic error handling
	[[ -z "$@" ]] && return 1
	#
	# Prevent the command from being canceled when the warning is being sent
	trap '' INT TERM TSTP
	#
	# Send the silent alert
	echo "⚠️⚠️⚠️: $USER/$UID from $userIP on $TTY -- With, EUID $EUID ran: $*" | tee -a "$PKGLOG" | systemd-cat -t "sshd-internal" -p 3
	#
	# Remove the trap
	trap - INT TERM TSTP
}
#
# Alert on suspicious commands
ssh() {
	# Send a warning
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
	# Send a warning
	warn "su $*"
	#
	# Gaslight with a fake root terminal
	if [[ "$EUID" == 0 && -n "$*" || "$*" == *"root"* ]]; then
		exec unshare -rm /bin/bash -c '
			mount -t tmpfs tmpfs /etc
			mount -t tmpfs tmpfs /home
			mount -t tmpfs tmpfs /root
			declare -x USER=root
			declare -x PS1="root@\h \w \$ "
			declare -x HOME="/root"
			cd /root
			whoami() {
				echo "root"
			}
			logname() {
				echo "root"
			}
			id() {
				if [[ -z $* ]]; then
					echo "uid=0(root) gid=0(root) groups=0(root)"
				else
					builtin command id $@
				fi
				return
			}
			declare -rfx whoami logname id
			exec /bin/bash
		'
	fi
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
	# Send a warning
	warn "chpasswd $@"
	return 0
}
#
# Prevent removal of traces
rm() {
	# Send a warning
	warn "rm $*"
	#
	# Use find to pretend like its actually deleting shit
	for i in "$@"; do
		find "$i" &>/dev/null
	done
}
history() {
	# Send a warning
	warn "history $*"
	#
	# Backup their history
	for i in "$@"; do
		if [[ "$i" != "-c" ]]; then
			cp ~/.rbash_history "/var/tmp/$(whoami)-via-$(logname)-cmd-hist"
			return 0
		fi
	done
	builtin command history $@
}
#
# Slightly impede attempts to escape securecloak.
command() {
	if [[ -z "$*" ]]; then
		echo "bash: $(printf -- "%s" "$*" | awk '{ print $1 }'): Permission denied" 1>&2
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
	sleep .1
	su
}
declare -rfx chpasswd sudo su ssh history rm warn bash env
declare -rx HOME TTY userIP SSH_CONNECTION PATH PKGLOG PROMPT_COMMAND HISTCONTROL HISTIGNORE




#
# Session Logging
#
# Log the entire session to a file.
function sessionLog() {
	if [[ -z "$logging" ]]; then
		local logDir="/var/tmp"
		local prefix="$USER-on-$(\logname)-"
		local count=1
		#
		# Determine the final log file path
		while [[ -f "${logDir}/${prefix}${count}.raw" ]]; do
			(( count++ ))
		done
		local log="${logDir}/${prefix}${count}.log"
		#
		# Cleanup the logs when shell exits
		trap 'sed -E "s/\x1B\[\??[0-9;]*[a-zA-Z]//g; s/\x1B\(B//g; s/\x08+//g; s/\r//g" "$log" 2>/dev/null | tee "$log"' EXIT
		#
		# Start logging
		declare -rx logging='y'
		exec script -qf "$log"
	fi
}
sessionLog
unset sessionLog