#!/usr/bin/bash
# Variables
declare -rx PKGLOG="/var/tmp/install.log" # The location to send warnings to
declare -r LD_PRELOAD='/opt/chaos-chaos.so' # Defensive library to use to deny permissions to files in the event BullSH is bypassed.
declare -r passHash='a88aab92b40add9e567f4c5546abe499091f1542c703f1616df863ab82be773a826b8838af41941760ab9b7effa64fa73c5216429163a8ccdd1086353b1b783d' # Password hash
declare -r hashRounds=250 # How many times to hash inputs
counts=0 # The amount of login attempts to start with
declare -r maxCounts=3 # The max amount of login attempts before all inputs silently fail
fuckOff="n" # Whether the script stops checking for the password (y/n)
hostname="$(hostname | awk -F'.' '{ print $1 }')" # Hostname of the machine up to the first dot (exclusive of first dot)
PS1="$USER@$hostname ~ $ " # The prompt to show on each new line
annoyanceType="confusion" # What kind of annoyance on a wrong password shall await them?
userIP="Local Console" ; [ -n "$SSH_CONNECTION" ] && userIP=$(printf "$SSH_CONNECTION" | awk '{ print $1 }') # Grab the SSH IP (with fallback)
#
# Handle various termination signals
trap 'stty sane; printf "\n$PS1"' INT
trap '' TERM TSTP QUIT
trap 'exit 0' HUP
#
# Function to log likely intrusions
warn() {
	# Send identifiers to the specified log file
	printf "Failed 2FA from user ($USER), UID ($EUID) originating from IP ($userIP). Input was: ($*)\n" | tee -a "$PKGLOG" &>/dev/null
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
			printf "\e[%d;%dH%s" "$r" "$c" "$(head -c 2 /dev/urandom | tr -d '\0')"
		done
		#
		# Move cursor to the bottom and show it again so your prompt is clean
		printf "\e[%d;1H$PS1" "$rows"
		tput cnorm
	fi
	return 0
}
#
# Hashing function
hash() {
	# Hash the input
	for ((i=0; i<hashRounds; i++)); do
		local input=$(printf -- "%s" "$input" | sha512sum | awk '{print $1}')
	done
	#
	# Return the hash
	printf "$input"
	return 0
}
#
# Function to check input
inputCheck() {
	# Increment the amount of attempts used
	(( counts++ ))
	#
	# If failed attempts exceed 3, stop checking for the correct password.
	if (( counts > "3" )) && [ "$fuckOff" != "y" ]; then
		readonly fuckOff="y"
	fi
	#
	# Check the input
	if [ -z "$input" ]; then
		return 0
	elif [[ "$input" == *"/"* ]]; then
		for i in "$input"; do
			if [[ "$i" == *"/"* ]]; then
				echo "rbash: $i: cannot specify '/' in command names" 1>&2
				return 1
			fi
		done
	elif [[ "$input" == "exit" || "$input" == "logout" ]]; then
		exit 0
	elif builtin which $(printf -- "%s" "$input" | awk '{ print $1 }') &>/dev/null || builtin type $(printf -- "%s" "$input" | awk '{ print $1 }') &>/dev/null; then
		# Send a warning
		warn "$input"
		#
		# If the input is a builtin or command in the $PATH, give a permission denied error.
		cmd=$(printf -- "%s" "$input" | awk '{ print $1 }')
		echo "rbash: $cmd: Permission denied" 1>&2
		#
		# Add command to history
		history -s "$input"
	elif [ "$fuckOff" == "n" ] && [ "$(hash)" == "$passHash" ]; then
		# If the input is the password, enter a real shell
		trap - INT TERM TSTP QUIT
		unset passHash userIP hostname counts fuckOff HISTFILE HISTSIZE
		builtin exec /usr/bin/bash --rcfile "/opt/securecloak.sh" -i
	else
		# Send a warning
		warn "$input"
		#
		# If the input is not the password, a shell builtin or a command in the $PATH, give a not found error.
		cmd=$(printf -- "%s" "$input" | awk '{ print $1 }')
		echo "rbash: $cmd: command not found" 1>&2
		#
		# Add command to history
		history -s "$input"
		#
		# Make some NOISE!!!
		annoyance &
	fi
}
#
# Fake an rBash terminal
while true; do
	# Take user input
	read -rep "$PS1" input
	#
	# Check input
	inputCheck
done