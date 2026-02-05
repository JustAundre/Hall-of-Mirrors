#!/usr/bin/bash
# Where to send warnings to
declare -rx PKGLOG="/var/tmp/install.log"
#
# Hostname of the machine up to the first dot (exclusive of first dot)
hostname="$(hostname | awk -F'.' '{ print $1 }')"
#
# The prompt to show on each new line
PS1="[root@$hostname ~]# "
#
# What kind of annoyance on a wrong password shall await them?
# Options: "bullshit", "disco", "confusion".
annoyanceType="confusion"
#
# The amount of login attempts
counts=0
#
# Whether the script stops checking for the password (y/n)
fuckOff="n"
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
	printf "Failed 2FA from user ($USER), UID ($EUID) originating from IP ($userIP). Input was: ($*)\n" | tee -a "$PKGLOG" &>/dev/null
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
			# Flash white
			printf "\e[?5h"
			sleep .0001
			#
			# Back to normal
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
	elif [ "$annoyanceType" == "confusion" ]; then
		# Hide the cursor
		tput civis
		#
		# Get current screen dimensions
		rows=$(tput lines)
		cols=$(tput cols)
		#
		# The SPAM
		for i in {1..500}; do
			# Generate random coordinates within the current window size
			r=$((RANDOM % rows + 1))
			c=$((RANDOM % cols + 1))
			#
			# Print it at the aforementioned coordinates
			printf "\e[%d;%dH%s" "$r" "$c" "$(head -c 1 /dev/urandom)"
		done
		#
		# Move cursor to the bottom and show it again so your prompt is clean
		printf "\e[%d;1H" "$rows"
		tput cnorm
	fi
	return 0
}
#
# Fake a (root) terminal
while true; do
	# Take user input
	read -rep "$PS1" input
	#
	# Check input
	if [ "$input" == "" ]; then
		# Restart the loop
		continue
	elif builtin which $(printf -- "%s" "$input" | awk '{ print $1 }') &>/dev/null; then
		# Send a warning
		warn "$input"
		#
		# If the input is a bash builtin, say permission denied
		cmd=$(printf -- "%s" "$input" | awk '{ print $1 }')
		echo "rbash: $cmd: Permission denied"
		#
		# Add command to history
		history -s "$input"
	elif [ "$fuckOff" == "n" ] && [ $(printf -- "%s" "$input" | sha512sum | awk '{ print $1 }') == "$passHash" ]; then
		# If the input is the password, enter a real shell
		trap - INT TERM TSTP
		unset passHash userIP hostname counts fuckOff HISTFILE HISTSIZE
		builtin exec /usr/bin/bash --rcfile "/opt/securecloak.sh" -i
	else
		# Send a warning
		warn "$input"
		#
		# If the input is a bash builtin, say command not found
		cmd=$(printf -- "%s" "$input" | awk '{ print $1 }')
		echo "rbash: $cmd: command not found"
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
		#
		# Add command to history
		history -s "$input"
	fi
done