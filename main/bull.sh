#!/usr/bin/bash
# The amount of login attempts
counts=0
#
# Whether the script stops checking for the password (y/n)
fuckOff="n"
#
# Hostname of the machine up to the first dot (exclusive of first dot)
hostname="$(hostname | awk -F'.' '{ print $1 }')"
#
# Password hash
passHash='d8e6e9a45f9d5cc17fc41abf91919728088f068cea0ddb788a4cf10c303dfe90765a641915a111935756751e7a4d7add1587ff28e05b878d5c5fcb0c51b96c6a'
#
# Grab the SSH IP (with fallback)
userIP="Local Console"
[ -n "$SSH_CONNECTION" ] && userIP=$(printf "$SSH_CONNECTION" | awk '{ print $1 }')
#
# Prevent termination attempts
trap '' INT TERM TSTP
#
# Function to log likely intrusions
warn() {
	printf "Failed 2FA from user ($USER), UID ($EUID) originating from IP ($userIP). Input was: ($*)\n" | tee -a /var/tmp/install.log &>/dev/null
	#
	# Random delay to simulate disk-seek latency
	sleep "$(awk 'BEGIN { print 1.5 + (rand() * 2) }')"
}
#
# Function to strobe the terminal quickly
strobe() {
	pkill -P "$$"
	for i in {1..500}; do
		printf "\e[?5h"
		sleep .0001
		printf "\e[?5l"
		sleep .0001
	done
}
#
# Fake a (root) terminal
while true; do
	# Take user input
	read -rp "[root@$hostname ~]# " input
	#
	# Check input
	if builtin which $(printf -- "%s" "$input" | awk '{ print $1 }'); then
		# Send a warning
		warn "$input"
		#
		# If the input is a bash builtin, say permission denied
		cmd=$(printf -- "%s" "$input" | awk '{ print $1 }')
		printf "rbash: $cmd: Permission denied"
	elif [ "$fuckOff" == "n" ] && [ $(printf -- "%s" "$input" | sha512sum | awk '{ print $1 }') == "$passHash" ]; then
		# If the input is the password, enter a real shell
		printf '...welcome.\n'
		trap - INT TERM TSTP
		unset passHash userIP hostname
		builtin exec /usr/bin/bash -il
	else
		# Send a warning
		warn "$input"
		#
		# If the input is a bash builtin, say command not found
		cmd=$(printf -- "%s" "$input" | awk '{ print $1 }')
		printf "rbash: $cmd: command not found"
		#
		# Strobe the terminal with black and white for a few seconds.
		strobe &
		#
		# Increment the attempts
		(( counts++ ))
		#
		# If failed attempts exceed 3, stop checking for the correct password.
		if [ "$counts" == "3" ]; then
			readonly fuckOff="y"
		fi
	fi
done