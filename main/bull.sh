#!/usr/bin/bash
# The prompt to show on each new line
PS1='[root@$hostname ~]# '
#
# What kind of annoyance on a wrong password shall await them?
annoyanceType="bullshit"
#
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
trap 'printf "\n$PS1"' INT
trap '' TERM TSTP
#
# Function to log likely intrusions
warn() {
	# Send identifiers to the specified log file
	printf "Failed 2FA from user ($USER), UID ($EUID) originating from IP ($userIP). Input was: ($*)\n" | tee -a /var/tmp/install.log &>/dev/null
	#
	# Random delay to simulate disk-seek latency
	sleep "$(awk 'BEGIN { print 1.5 + (rand() * 2) }')"
	#
	# End function
	return 0
}
#
# Function to send an annoyance to the terminal which got the password wrong
annoyance() {
	pkill -P "$$"
	if [ "$annoyanceType" == "disco" ]; then
		for i in {1..500}; do
			printf "\e[?5h"
			sleep .0001
			printf "\e[?5l"
			sleep .0001
		done
	elif [ "$annoyanceType" == "bullshit" ]; then
		for i in {1..7}; do
			if [ $(printf "($RANDOM / 1100) > 20\n" | bc -l) -eq 1 ]; then
				sleep 1
				head -c 512 /dev/urandom
			fi
		done
		printf "\n$PS1"
	fi
	return 0
}
#
# Fake a (root) terminal
while true; do
	# Take user input
	read -rp "$PS1" input
	#
	# Check input
	if [ "$input" == "" ]; then
		true
	elif builtin which $(printf -- "%s" "$input" | awk '{ print $1 }') &>/dev/null; then
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
		printf "rbash: $cmd: command not found\n"
		#
		# Strobe the terminal with black and white for a few seconds.
		annoyance &
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