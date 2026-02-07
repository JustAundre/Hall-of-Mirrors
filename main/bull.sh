#!/usr/bin/bash
#
# Anti-DDoSing
#
# Kill duplicate sessions from the same user
pgrep -f "$0" -u "$USER" | grep -v "^$$\$" | xargs kill -9 2>/dev/null
#
# In the event the fake shell is escaped, near-immediately kick them.
declare -x TMOUT=1





#
# Environment
#
declare -rx PKGLOG="/var/tmp/install.log" # The location to send warnings to
declare -r LD_PRELOAD='/opt/chaos-chaos.so' # Defensive library to use to deny permissions to files in the event BullSH is bypassed.
declare -r passHash1='f02016bf576c54bc5f3160ae1a682b74d00f3d69be709a31dc20a43114627becd08ea97fb203c00492db42526208e4d92ce949f4ad99012500307dd27ecdf3dc' # Password hash for the 1st MFA layer
declare -r passHash2='f02016bf576c54bc5f3160ae1a682b74d00f3d69be709a31dc20a43114627becd08ea97fb203c00492db42526208e4d92ce949f4ad99012500307dd27ecdf3dc' # Password hash for the 2nd MFA layer
declare -r hashRounds=2500 # How many times to hash inputs
declare -r readTimeout=20 # How many seconds before timing out for inactivity
declare -r maxCounts=3 # The max amount of login attempts before all inputs silently fail
declare -r mfaLayers=3 # How many layers of MFA do you want? (Max 3)
mfaAt=1 # What layer of the MFA you're at (don't change)
counts=0 # The amount of login attempts to start with (don't change)
fuckOff="n" # Whether the script stops checking for the password (y/n)
HOSTNAME="$(hostname | awk -F'.' '{ print $1 }')" # Hostname of the machine up to the first dot (exclusive of first dot)
PS1="$USER@$HOSTNAME ~ $ " # The prompt to show on each new line
annoyanceType="none" # What kind of annoyance on a wrong password shall await them?
userIP="Local Console" ; [ -n "$SSH_CONNECTION" ] && userIP=$(printf "$SSH_CONNECTION" | awk '{ print $1 }') # Grab the SSH IP (with fallback)
#
# Handle various termination signals
trap 'stty sane; printf "\n$PS1"' INT
trap '' TERM TSTP QUIT
trap 'pkill -P $$; exit 0' HUP
trap 'pkill -P $$; exit 0' EXIT





#
# Helper Functions
#
# Send identifiers to a log file
warn() {
	echo "⚠️ MFA layer 1 failed by $USER, UID $EUID -- originating from $userIP. Input was: $*\n" | tee -a "$PKGLOG" &>/dev/null
	return
}
#
# Function to send an annoyance to the terminal which got the password wrong
annoyance() {
	# Stop previously triggered annoyances to prevent stacking and spiked CPU usage
	pkill -P "$$"
	#
	# Flash black and white really fast for a few seconds
	if [ "$annoyanceType" == "disco" ]; then
		for i in {1..500}; do
			printf "\e[?5h"
			sleep .0001
			printf "\e[?5l"
			sleep .0001
		done
	# Throw a wall of random bullshit at the terminal
	elif [ "$annoyanceType" == "bullshit" ]; then
		for i in {1..7}; do
			if [ $(echo "($RANDOM / 1100) > 20" | bc -l) -eq 1 ]; then
				sleep 1
				head -c 512 /dev/urandom
			fi
		done
		printf "\n$PS1"
	# Splatter random bullshit onto the terminal
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
	else
		return 1
	fi
	return 0
}
#
# Function to hash input
hash() {
	printf -- "%s" "$input" | python3 -c "import hashlib, sys; h = sys.stdin.read().encode(); [h := hashlib.sha512(h).hexdigest().encode() for _ in range($hashRounds)]; print(h.decode())"
}
#
# Function to pass into the real shell
passOff() {
	# Log the successful attempt
	echo "✅ MFA layer $mfaAt passed by $USER, UID $EUID -- originating from $userIP." | tee -a "$PKGLOG" &>/dev/null
	#
	# Reset the attempt counter
	counts=0
	#
	# Remove sig traps
	trap - INT TERM TSTP QUIT HUP EXIY
	#
	# Remove unecessary variables
	unset userIP HOSTNAME counts fuckOff HISTFILE HISTSIZE
	#
	# Unset the timeout
	unset TMOUT
	#
	# If allowed, last layer.
	if [ "$mfaLayers" -eq 3 ]; then
		builtin exec /usr/bin/bash --rcfile "/opt/securecloak.sh" -i
	else
		builtin exec /usr/bin/bash -i
	fi
}
#
# Function to check input
inputCheck() {
	# Increase the amount of login attempts by 1
	(( counts++ ))
	#
	# If failed attempts exceed 3, stop checking for the correct password.
	[ "$counts" -gt 3 ] && [ "$fuckOff" != "y" ] && readonly fuckOff="y"
	#
	# Check the input
	if [ -z "$input" ]; then
		return 0
	elif [[ "$input" == *"/"* ]]; then
		# Send a warning
		warn "$input"
		#
		# Check each argument of the input and see if it has a forward slash
		read -ra args <<< "$input"
		for i in "$args"; do
			if [[ "$i" == *"/"* ]]; then
				echo "rbash: $i: cannot specify '/' in command names" 1>&2
				return 1
			fi
		done
		#
		# Add command to history
		history -s "$input"
		#
		# Fail the attempt
		return 1
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
		#
		# Fail the attempt
		return 1
	elif [ "$mfaAt" -eq 1 ] && [ "$fuckOff" == "n" ] && [ "$(hash)" == "$passHash1" ]; then
		# If the input is the password pass the attempt
		return 0
	elif [ "$mfaAt" -eq 2 ] && [ "$fuckOff" == "n" ] && [ "$(hash)" == "$passHash2" ]; then
		# If the input is the password pass the attempt
		return 0
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
		#
		# Fail the attempt
		return 1
	fi
}





#
# The Backbone
#
# Trap user in a while loop over a fake terminal
while true; do
	# Take user input
	[ "$mfaAt" -eq 1 ] && read -t "$readTimeout" -rep "$PS1" input || exit 0
	#
	# Check input
	if inputCheck && [ "$mfaLayers" -gt 1 ]; then
		(( mfaAt++ ))
		echo "This account is currently not available."
		while true; do
			read -t "$readTimeout" -re input || exit 0
			if inputCheck; then
				passOff
			fi
		done
	else
		passOff
	fi
done